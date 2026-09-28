<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateInternalService
{
    /**
     * Handle an internal service request authenticated with a shared secret.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $configuredToken = (string) config('services.realtime.internal_token');
        $providedToken = (string) $request->header('X-Internal-Service-Token');

        abort_if(
            $configuredToken === ''
                || $providedToken === ''
                || ! hash_equals($configuredToken, $providedToken),
            Response::HTTP_UNAUTHORIZED,
        );

        return $next($request);
    }
}
