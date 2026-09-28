<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Quote\StoreBatchQuoteRequest;
use App\Http\Requests\Api\V1\Quote\StoreQuoteRequest;
use App\Http\Resources\Api\V1\QuoteResource;
use App\Models\User;
use App\Services\Quote\QuoteService;
use Illuminate\Http\JsonResponse;

class QuoteController extends Controller
{
    public function batch(
        StoreBatchQuoteRequest $request,
        QuoteService $quoteService,
    ): JsonResponse {
        $user = $request->user();
        assert($user instanceof User);

        return QuoteResource::collection(
            $quoteService->createBatch($user, $request->validated()),
        )->response()->setStatusCode(201);
    }

    public function __invoke(
        StoreQuoteRequest $request,
        QuoteService $quoteService,
    ): QuoteResource {
        $user = $request->user();
        assert($user instanceof User);

        $quote = $quoteService->create($user, $request->validated());

        return new QuoteResource($quote);
    }
}
