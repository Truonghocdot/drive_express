<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\WalletResource;
use App\Models\User;
use App\Services\Finance\TopupService;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function show(Request $request, TopupService $topups): WalletResource
    {
        $user = $request->user();
        assert($user instanceof User);
        $entriesLimit = min(max($request->integer('entries_limit', 50), 1), 100);
        $wallet = $topups->ensureWallet($user)->load([
            'ledgerAccount.entries' => fn ($query) => $query
                ->with('transaction')
                ->latest('id')
                ->limit($entriesLimit),
        ]);

        return new WalletResource($wallet);
    }
}
