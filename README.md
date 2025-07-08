# Local AI Command Executor

Utilize an ultra-cheap local LLM to execute your own PowerShell functions using natural language requests. This script acts as a "function dispatcher," sending your plain-English commands to a local AI model, which then selects the appropriate PowerShell function to run from a list it automatically discovers in your profile.

![Demo GIF showing the tool in action](https://i.imgur.com/your-demo.gif) 
*(Note: You can create a GIF like this to show a quick demo)*

## Features

- **Natural Language Execution**: Run complex PowerShell functions without remembering their names (e.g., `> find all large log files in my temp folder`).
- **Automatic Function Discovery**: No need to manually register commands. The script automatically finds any function you add to your PowerShell profile.
- **100% Local & Private**: Your commands are sent to a model running on your own machine. No data ever leaves your computer.
- **Interactive & Secure**: The script always shows you the command the AI wants to run and asks for your approval before executing anything.
- **Model Agnostic**: Works with a wide variety of models supported by LM Studio, with a recommendation for small, fast models.

## Requirements

1.  **PowerShell**: The script is designed for Windows PowerShell 5.1 or PowerShell 7+.
2.  **LM Studio**: A free application for running local LLMs. [Download it here](https://lmstudio.ai/).
3.  **A Small, Instruction-Tuned Local LLM**: The model's ability to follow instructions is critical. We recommend:
    *   **Microsoft Phi-3 Mini Instruct**: An excellent, modern model that provides a great balance of speed and capability.
    *   **Google Gemma 2B-Instruct (`-it`)**: A very fast and lightweight model, perfect for ensuring instant responses.

### Why an "Instruct" Model is Essential

It's crucial to use an **instruct-tuned** model (usually with `-instruct` or `-it` in the name) rather than a base model.

*   **Base models** (like the base `Gemma 3`) are brilliant at predicting text but don't know how to follow orders. They might ignore the script's rules and provide extra commentary, which will cause the command to fail.
*   **Instruct models** have been specifically trained to follow commands, like "Respond ONLY with the command name." This is the single most important factor for this script to work reliably. A slightly older instruct model will always perform better here than a newer base model.

---

## ⚙️ Setup Guide

Follow these steps to get the AI Command Executor running.

### Step 1: Set Up LM Studio & Download a Model

1.  **Install and open LM Studio.**
2.  **Download a Model**:
    *   In the LM Studio search bar (magnifying glass icon 🔍), search for a recommended instruct model like `Phi-3 Mini Instruct` or `Gemma 2B Instruct`.
    *   Look for a quantized version (e.g., one with `Q4_K_M` in the name) from a trusted creator (like `microsoft` or `google`). This provides a good balance of performance and size. Download it.
3.  **Start the Local Server**:
    *   Navigate to the local server tab (two arrows icon ↔️).
    *   At the top, select the model you just downloaded.
    *   Click **Start Server**.
    *   Leave it running in the background. The server must be active on the default port `1234` for the script to work.

### Step 2: Configure Your PowerShell Profile

Your PowerShell profile is a script that runs every time you open a new terminal. We will add the AI Command Executor and your custom functions here.

1.  **Check for an existing profile**:
    ```powershell
    Test-Path $PROFILE
    ```
2.  **If it returns `False`**, create a new profile file:
    ```powershell
    New-Item -Path $PROFILE -Type File -Force
    ```
3.  **Open your profile in a text editor**. Notepad works, but a code editor like VS Code is better.
    ```powershell
    notepad $PROFILE
    # Or for VS Code:
    # code $PROFILE
    ```

### Step 3: Add the Code to Your Profile

1.  Copy the entire content of the `local-ai-command-executor.ps1` script.
2.  Paste it directly into your profile file that you opened in the previous step.

### Step 4: Add Your Own Custom Functions

This is where the magic happens. Add your own PowerShell functions to your profile file so the AI can use them. The script will automatically discover them.

Here are a few examples to get you started. **Add these to your profile file below the script code.**

```powershell
# === MY CUSTOM FUNCTIONS ===

# Example 1: Get the weather
function Get-Weather {
    Invoke-RestMethod -Uri "wttr.in/?format=3"
}

# Example 2: Open a specific project directory and launch VS Code
function Start-MyProject {
    # --- IMPORTANT: Change this path to your own project folder! ---
    cd "C:\Path\To\Your\Project"
    code .
    Write-Host "Project folder opened in VS Code."
}

# Example 3: Search your command history
function Search-MyHistory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SearchTerm
    )
    Get-History | Where-Object { $_.CommandLine -like "*$SearchTerm*" } | Select-Object -Last 10
}
```

### Step 5: Reload Your Profile

Save your profile file. To apply the changes, you can either:
1.  Close and re-open your PowerShell terminal.
2.  Or, run this command in your current session:
    ```powershell
    . $PROFILE
    ```
You should see a message saying "AI Profile: Ready! Use '>' to run AI commands."

---

## 🚀 Usage

To use the tool, type `>` followed by your request in plain English. The script will interpret your request and ask for permission to run the corresponding function.

**Examples (based on the functions above):**

*   To get the weather:
    ```powershell
    > what is the weather today
    ```
    *(The AI should choose `Get-Weather`)*

*   To open your project:
    ```powershell
    > open my main project
    ```
    *(The AI should choose `Start-MyProject`)*

*   To search for a command you used previously:
    ```powershell
    > find the docker command I ran
    ```
    *(The AI should choose `Search-MyHistory` and prompt you for a search term)*

## How It Works

1.  When your profile loads, the script inspects it to find all available functions, creating a list for the AI.
2.  When you run `> your request`, the script constructs a system prompt containing your request and the list of allowed functions.
3.  It sends this payload to your local LM Studio server.
4.  The LLM analyzes the request and responds with the name of the single most appropriate function.
5.  The script validates that the AI's response is a real, existing command.
6.  It prompts you for confirmation (`[Y/N]`).
7.  If you approve, it executes the command using `Invoke-Expression`.

## ⚠️ A Note on Security

This script is designed with safety in mind. The AI **cannot** invent its own commands or run arbitrary code. It can only choose from the list of functions you have explicitly defined in your `$PROFILE`. Furthermore, the interactive confirmation step ensures that no command is ever run without your direct approval.

## Troubleshooting

-   **"Could not contact the LM Studio server"**: Make sure LM Studio is running and you have clicked "Start Server" in the server tab.
-   **"Model returned a non-existent or invalid command"**:
    *   Your model might be "hallucinating." Try a different model (instruction-tuned models are best).
    *   Rephrase your request to be more direct and clear.
    *   Ensure the function you want to run exists in your profile and your profile has been reloaded.