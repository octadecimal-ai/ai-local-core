<?php
/**
 * Przykładowa implementacja endpointów polling dla serwera OVH
 * 
 * Endpointy do zaimplementowania w Waldus API lub osobnym serwisie
 */

// Przykład użycia z Laravel (dla waldus-api)

// routes/api.php
Route::prefix('ollama')->group(function () {
    // Polling - lokalny PC pyta czy ma zapytanie
    Route::get('/poll', [OllamaPollingController::class, 'poll']);
    
    // Odpowiedź - lokalny PC zwraca wynik
    Route::post('/response', [OllamaPollingController::class, 'response']);
    
    // Zapytanie - Waldus API wysyła zapytanie
    Route::post('/request', [OllamaPollingController::class, 'request']);
    
    // Status - sprawdzanie statusu zapytania
    Route::get('/status/{id}', [OllamaPollingController::class, 'status']);
});

// app/Http/Controllers/OllamaPollingController.php
class OllamaPollingController extends Controller
{
    // Kolejka zapytań (można użyć Redis, bazy danych, lub cache)
    private function getQueue()
    {
        // Przykład z cache Laravel
        return Cache::store('redis');
    }
    
    /**
     * GET /api/ollama/poll
     * Lokalny PC pyta czy ma zapytanie
     */
    public function poll()
    {
        $queue = $this->getQueue();
        
        // Pobierz pierwsze zapytanie z kolejki
        $request = $queue->pull('ollama:queue');
        
        if ($request) {
            // Oznacz jako przetwarzane
            $queue->put("ollama:processing:{$request['id']}", $request, 300); // 5 min timeout
            
            return response()->json([
                'has_request' => true,
                'request' => $request
            ]);
        }
        
        // Brak zapytania
        return response()->noContent(204);
    }
    
    /**
     * POST /api/ollama/response
     * Lokalny PC zwraca odpowiedź
     */
    public function response(Request $request)
    {
        $data = $request->validate([
            'id' => 'required|string',
            'response' => 'required|string',
            'success' => 'boolean',
            'error' => 'nullable|string',
            'model' => 'nullable|string',
        ]);
        
        $queue = $this->getQueue();
        $requestId = $data['id'];
        
        // Zapisz odpowiedź
        $queue->put("ollama:response:{$requestId}", $data, 3600); // 1h
        
        // Usuń z przetwarzania
        $queue->forget("ollama:processing:{$requestId}");
        
        return response()->json(['success' => true]);
    }
    
    /**
     * POST /api/ollama/request
     * Waldus API wysyła zapytanie
     */
    public function request(Request $request)
    {
        $data = $request->validate([
            'prompt' => 'required|string',
            'system_prompt' => 'nullable|string',
            'model' => 'nullable|string',
            'temperature' => 'nullable|numeric|min:0|max:2',
            'max_tokens' => 'nullable|integer|min:1|max:8000',
        ]);
        
        $requestId = 'req_' . uniqid() . '_' . time();
        
        $queueItem = [
            'id' => $requestId,
            'prompt' => $data['prompt'],
            'system_prompt' => $data['system_prompt'] ?? null,
            'model' => $data['model'] ?? 'qwen2.5:7b',
            'temperature' => $data['temperature'] ?? 0.7,
            'max_tokens' => $data['max_tokens'] ?? 2000,
            'created_at' => now()->toIso8601String(),
        ];
        
        // Dodaj do kolejki
        $queue = $this->getQueue();
        $queue->push('ollama:queue', $queueItem);
        
        return response()->json([
            'id' => $requestId,
            'status' => 'queued'
        ], 202);
    }
    
    /**
     * GET /api/ollama/status/{id}
     * Sprawdzanie statusu zapytania
     */
    public function status($id)
    {
        $queue = $this->getQueue();
        
        // Sprawdź czy jest odpowiedź
        $response = $queue->get("ollama:response:{$id}");
        if ($response) {
            return response()->json([
                'id' => $id,
                'status' => 'completed',
                'response' => $response['response'],
                'model' => $response['model'] ?? null,
            ]);
        }
        
        // Sprawdź czy jest w przetwarzaniu
        $processing = $queue->get("ollama:processing:{$id}");
        if ($processing) {
            return response()->json([
                'id' => $id,
                'status' => 'processing',
            ]);
        }
        
        // Sprawdź czy jest w kolejce
        $queueItems = $queue->get('ollama:queue', []);
        $inQueue = collect($queueItems)->firstWhere('id', $id);
        if ($inQueue) {
            return response()->json([
                'id' => $id,
                'status' => 'queued',
            ]);
        }
        
        return response()->json([
            'id' => $id,
            'status' => 'not_found',
        ], 404);
    }
}

/**
 * Przykład użycia w Waldus API (OllamaProvider.php)
 */
class OllamaProvider implements LLMProvider
{
    public function complete(array $promptData): array
    {
        // Zamiast wywoływać lokalny Python, wyślij zapytanie do serwera OVH
        $response = Http::post(config('services.ollama.server_url') . '/api/ollama/request', [
            'prompt' => $promptData['user'] ?? $promptData['prompt'],
            'system_prompt' => $promptData['system'] ?? null,
            'model' => $promptData['model'] ?? 'qwen2.5:7b',
            'temperature' => $promptData['temperature'] ?? 0.7,
            'max_tokens' => $promptData['max_tokens'] ?? 2000,
        ]);
        
        $requestId = $response->json('id');
        
        // Czekaj na odpowiedź (polling)
        $maxWait = 120; // 2 minuty
        $startTime = time();
        
        while (time() - $startTime < $maxWait) {
            sleep(2); // Czekaj 2 sekundy
            
            $statusResponse = Http::get(
                config('services.ollama.server_url') . "/api/ollama/status/{$requestId}"
            );
            
            $status = $statusResponse->json('status');
            
            if ($status === 'completed') {
                return [
                    'text' => $statusResponse->json('response'),
                    'model' => $statusResponse->json('model'),
                ];
            }
            
            if ($status === 'error') {
                throw new \Exception('Ollama processing error');
            }
        }
        
        throw new \Exception('Ollama request timeout');
    }
}

