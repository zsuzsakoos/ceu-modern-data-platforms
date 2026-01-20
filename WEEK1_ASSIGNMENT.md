# CEU Data Engineering 2 - Modern Data Platforms - Assignment - Week 1

## Fork this repo
1) Please fork this repo as a **private repository**. Don't worry about any changes you made to your work on Monday; I updated the `airbnb` folder of this repository so it exactly reflects how far we've gone
2) Clone it to your local machine (not by downloading the zip but with the git command using the https/ssh link from github)

### Invite collaborators (GitHub web UI)

1. Open your repository on github.com.
2. Click "Settings" (top row of tabs).
3. In the left sidebar click "Manage access".
4. Click "Invite teams or people" (or "Invite a collaborator").
5. Type `zoltanctoth`, select the user, click "Add" or "Invite".
6. Repeat step 5 for `nai-coder`.
7. Choose the appropriate permission level (Write/Maintain) and confirm.

## Go through the Snowflake Setup App
Go through the [dbt setup app](https://dbtsetup.nordquant.com/?course=ceu) again. You'll see CEU in the header now. This is required because now the datasets for your assignment will be set up, too:

* Use the same Snowflake url, username (probably `admin`) and password you did in class
* As a side note, if you ever lose access to your Snowflake account, you can create a new trial, even using the same email address you already used

## Set up your project

1) Copy `profiles.yml` into the `airbnb` folder in your local copy of the forked repository

### Activate the virtualenv

> **Note (Windows PowerShell permissions):** If you see an error like
> 
> ```
> File C:\path\to\.venv\Scripts\Activate.ps1 cannot be loaded because running scripts is disabled on this system. For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
> ```
> 
> fix it by running PowerShell and executing:
> 
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
> ```
> 
> then restart Visual Studio Code and retry `uv sync` / activating the virtualenv.

> **Note (Windows PowerShell):** If you see a "command not found" error
> 
> Restart Visual Studio Code

2) Execute `uv sync` - uv has already been installed, so no need to reinstall it
3) Activate the virtualenv:
   - Windows (PowerShell): `.\.venv\Scripts\Activate.ps1`
   - Windows (CMD): `.venv\Scripts\activate.bat`
   - WSL (Windows Subsystem for Linux): `source .venv/bin/activate`
   - macOS / Linux: `source .venv/bin/activate`

### Get help
If you run into any issues you can't resolve:
1) Ask ChatGPT
2) Ask your peers
3) Teams/email me
4) If we can't work it out, you can fall back to working from the Codespace that comes with your repo

## Test your project

Execute `dbt run`. If it works, you are done.

# Submission

1) Commit your changes and push them to GitHub. Also add `profiles.yml` to git.
   > Generally speaking you would never push a file that has credentials to git.
   > But as we are in an instructional setting and this is a private repo, now it's OK to do so.

2) Submit the URL to your GitHub repository (the fork, that is) on Moodle under "Assignment - Week 1"

## Deadline
Because we need to ensure that you have a 100% working environment and will need time for some buffer fixing prolems, I'd like to ask you to get this done by **End of Day Thursday 22 Jan.**

Good Luck!
