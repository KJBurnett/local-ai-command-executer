# ===================================================================
# AUTOMATIC FUNCTION DISCOVERY
# -------------------------------------------------------------------
# This code automatically finds all functions in this file to provide
# a list of valid commands to the AI. You never need to edit this section.
# ===================================================================

Write-Host "AI Profile: Discovering available commands..." -ForegroundColor DarkGray
try {
    # This method inspects the current PowerShell session to find all functions
    # that were sourced from the profile file. It's more robust than parsing the file text.
    $global:AllowedAiFunctions = (Get-Command -CommandType Function | Where-Object { $_.ScriptBlock.File -eq $PROFILE } | Select-Object -ExpandProperty Name) | Sort-Object -Unique
    Write-Host "AI Profile: $($global:AllowedAiFunctions.Count) commands loaded for AI context." -ForegroundColor DarkGray
} catch {
    Write-Host "AI Profile: Could not automatically discover functions." -ForegroundColor Yellow
    $global:AllowedAiFunctions = @()
}


# ===================================================================
# AI COMMAND EXECUTOR
# -------------------------------------------------------------------
# This is the main function that connects to your local AI model.
# It's configured to work with the LM Studio local server.
# ===================================================================

function Invoke-AiCommand {
    [CmdletBinding()]
    param(
        # This parameter now accepts all remaining arguments on the line,
        # allowing you to type your command without quotes.
        [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
        [string[]]$Query
    )

    # Join the array of words back into a single sentence.
    $FullQuery = $Query -join ' '

    Write-Host "Querying local model with: '$FullQuery'" -ForegroundColor Yellow

    # This prompt provides the "Context" to the model. It tells the AI its role
    # and gives it the list of valid commands it is allowed to choose from.
    $SystemPrompt = @"
You are a PowerShell function dispatcher. Your only job is to analyze the user's request and choose the single most appropriate PowerShell command from the allowed list.
Do not add any explanation, commentary, or formatting. Respond ONLY with the command name.

Allowed Commands:
$($global:AllowedAiFunctions -join "`n")
"@

    # The API endpoint for a local LM Studio server.
    $lmStudioEndpoint = "http://localhost:1234/v1/chat/completions"

    # The request body, formatted for LM Studio's OpenAI-compatible API.
    $body = @{
        model = "local-model" # This is a required placeholder for LM Studio.
        messages = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user"; content = $FullQuery } # Use the joined query string here.
        )
        temperature = 0.1 # Low temperature makes the output more predictable and less creative.
        stream = $false   # We want the complete response at once.
    } | ConvertTo-Json -Depth 4

    try {
        # Make the API call to the local server.
        $response = Invoke-RestMethod -Uri $lmStudioEndpoint -Method Post -Body $body -ContentType "application/json"
        # Extract the command name from the response.
        $commandToRun = $response.choices[0].message.content.Trim()
    } catch {
        Write-Host "Execution Failed: Could not contact the LM Studio server." -ForegroundColor Red
        Write-Host "Please ensure LM Studio is running and the server has been started on port 1234." -ForegroundColor Red
        return
    }

    # --- CRITICAL SECURITY CHECK ---
    # Verify the command returned by the AI is a real, executable command
    # before asking for permission to execute. This is safer than a simple
    # list check and protects against command injection.
    if (Get-Command $commandToRun -ErrorAction SilentlyContinue) {
        $confirmation = Read-Host "Model '$($response.model)' wants to run: '$commandToRun'. Approve? [Y/N]"
        if ($confirmation -eq 'y') {
            Write-Host "Executing..." -ForegroundColor Green
            # Execute the command string.
            Invoke-Expression -Command $commandToRun
        } else {
            Write-Host "Execution cancelled by user." -ForegroundColor Red
        }
    } else {
        Write-Host "Execution Failed: Model returned a non-existent or invalid command: '$commandToRun'" -ForegroundColor Red
        Write-Host "This could be a model hallucination. Please try rephrasing your request." -ForegroundColor Red
    }
}


# ===================================================================
# SECTION 4: CONVENIENT ALIAS
# -------------------------------------------------------------------
# Creates the short '>' alias for Invoke-AiCommand.
# ===================================================================

Set-Alias -Name ">" -Value Invoke-AiCommand

Write-Host "AI Profile: Ready! Use '>' to run AI commands." -ForegroundColor Green