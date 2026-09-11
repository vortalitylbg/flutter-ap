<?php

namespace App\Utils;


use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\View;

/**
 * Utilitaire pour l'envoi d'emails via des templates Blade.
 */
class EmailHelpers
{
    /**
     * Envoie un email HTML généré à partir d'un template Blade.
     *
     * @param string $to       Adresse email du destinataire.
     * @param string $subject  Sujet de l'email.
     * @param string $template Nom du template Blade à utiliser (ex: 'emails.welcome').
     * @param array  $data     Variables à transmettre au template.
     */
    public static function sendEmail($to, $subject, $template, $data = []): void
    {
        $body = View::make($template, $data)->render();

        Mail::send([], [], function ($message) use ($to, $subject, $body) {
            $message->to($to)
                ->subject($subject)
                ->html($body);
        });
    }
}
