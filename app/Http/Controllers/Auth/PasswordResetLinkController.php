<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class PasswordResetLinkController extends Controller
{
    
    public function create(): View
    {
        return view('auth.forgot-password');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
        ]);

        $status = Password::sendResetLink(
            $request->only('email')
        );

        if ($status == Password::RESET_LINK_SENT) {
            // In debug/local mode, extract the reset URL from the log file
            // so developers can test without a real mail server
            if (config('app.debug') || app()->environment('local')) {
                $logPath = storage_path('logs/laravel.log');
                if (file_exists($logPath)) {
                    // Read last 50KB of log to find the latest reset link
                    $logSize = filesize($logPath);
                    $readSize = min($logSize, 50 * 1024);
                    $handle = fopen($logPath, 'r');
                    fseek($handle, -$readSize, SEEK_END);
                    $logContent = fread($handle, $readSize);
                    fclose($handle);

                    // Extract all reset-password URLs and take the last one
                    if (preg_match_all(
                        '/reset-password\/([a-zA-Z0-9]+)\?email=([^\s\"\'\\\\\n]+)/',
                        $logContent,
                        $matches
                    )) {
                        $lastIdx = count($matches[0]) - 1;
                        $token = $matches[1][$lastIdx];
                        $email = urldecode($matches[2][$lastIdx]);
                        // Clean up any trailing characters
                        $email = preg_replace('/[^a-zA-Z0-9@._\-].*$/', '', $email);
                        $resetUrl = route('password.reset', ['token' => $token, 'email' => $email]);
                        session(['dev_reset_url' => $resetUrl]);
                    }
                }
            }

            return back()->with('status', __($status));
        }

        return back()->withInput($request->only('email'))
                     ->withErrors(['email' => __($status)]);
    }
}
