<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Admin\AdminSessionController;
use App\Http\Requests\Auth\LoginRequest;
use App\Services\ActivityLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class AuthenticatedSessionController extends Controller
{
    
    public function create(Request $request): View
    {
        session(['url.intended' => url()->previous()]);

        return view('auth.login');
    }

    public function store(LoginRequest $request): RedirectResponse
    {
        $request->authenticate();

        $request->session()->regenerate();

        if (Auth::user()->isAdmin()) {
            AdminSessionController::recordSession($request);
            // Log admin login
            ActivityLogger::logLogin(Auth::user()->email);
        }

        return redirect()->intended(route('dashboard', absolute: false));
    }

    public function destroy(Request $request): RedirectResponse
    {
        if (Auth::check() && Auth::user()->isAdmin()) {
            \App\Models\AdminSession::where('user_id', Auth::id())
                ->where('token_id', session()->getId())
                ->update(['is_active' => false]);
            
            // Log admin logout
            ActivityLogger::logLogout(Auth::user()->email);
        }

        Auth::guard('web')->logout();

        $request->session()->invalidate();

        $request->session()->regenerateToken();

        return redirect('/');
    }
}

