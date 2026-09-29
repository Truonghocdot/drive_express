<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Finance\TopupService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class SePayWebhookController extends Controller
{
    public function __invoke(Request $request, TopupService $topups): JsonResponse
    {
        $data = Validator::validate($request->all(), [
            'id' => ['required', 'integer'],
            'referenceCode' => ['required', 'string', 'max:100'],
            'content' => ['required', 'string', 'max:1000'],
            'transferAmount' => ['required', 'numeric', 'min:1'],
            'transferType' => ['required', 'string', Rule::in(['in', 'IN'])],
        ]);
        $topup = $topups->complete(
            (string) $data['id'],
            $data['referenceCode'],
            $this->topupReference($data['content']),
            (float) $data['transferAmount'],
            $request->all(),
        );

        return response()->json(['data' => ['topup_id' => $topup->public_id]]);
    }

    private function topupReference(string $content): string
    {
        if (preg_match('/\b(TOPUP[A-Z0-9]{12})\b/i', $content, $matches) !== 1) {
            throw ValidationException::withMessages([
                'content' => ['Nội dung giao dịch không có mã nạp ví TOPUP hợp lệ.'],
            ]);
        }

        return mb_strtoupper($matches[1]);
    }
}
