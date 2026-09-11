<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HomeTest extends TestCase
{
    use RefreshDatabase;

    // -------------------------------------------------------------------------
    // GET /
    // -------------------------------------------------------------------------

    public function test_page_accueil_accessible(): void
    {
        $this->get(route('home'))->assertStatus(200);
    }

    // -------------------------------------------------------------------------
    // GET /api-doc
    // -------------------------------------------------------------------------

    public function test_page_api_doc_accessible(): void
    {
        $this->get(route('api-doc'))->assertStatus(200);
    }
}
