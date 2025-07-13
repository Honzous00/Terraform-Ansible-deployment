# Terraform-Ansible-Deployment

## 🇬🇧 Automated Deployment and Configuration of iTop on Proxmox LXC Containers

This project provides a set of Infrastructure as Code (IaC) scripts using **Terraform** for Proxmox LXC container provisioning and **Ansible** for automated software installation and configuration. The primary goal is to deploy and set up an **iTop** (IT Operations Portal) instance efficiently and repeatably within a Proxmox Virtual Environment.

This project was developed as my **Final Project (Absolventská práce)** at a **Higher Vocational School (Vyšší odborná škola)**.

-----

### Features

  * **Proxmox LXC Provisioning:** Automatically creates a Debian 12 LXC container on Proxmox using Terraform.
  * **Automated Software Installation:** Installs and configures necessary components including:
      * **PHP:** Installs PHP (version 8.1 by default, with an option for 7.4) and essential extensions for iTop.
      * **Apache2:** Sets up the Apache web server.
      * **MariaDB:** Installs MariaDB 11.5, configures root password, and sets up remote access.
      * **iTop CMDB:** Downloads and deploys iTop (version 3.2.0 by default, with options for 3.1.1, 3.1.2) to the web server.
      * **iTop Toolkit:** Installs the iTop Toolkit for post-installation tasks.
  * **Dynamic IP Handling:** Automatically fetches the LXC's IP address and adds it to an Ansible inventory file.
  * **Container Renaming:** Renames the created LXC container based on the installed PHP and iTop versions for better identification.
  * **Customizable:** Easily adaptable to different PHP and iTop versions by uncommenting relevant Ansible playbooks.

-----

### Prerequisites

Before running these scripts, ensure you have the following:

  * **Proxmox VE Server:** A running Proxmox Virtual Environment.
  * **SSH Access to Proxmox:** Root SSH access to your Proxmox host. The Bash script uses `ssh root@$PROXMOX_IP`.
  * **Terraform:** [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
  * **Ansible:** [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed on your local machine.
  * **SSH Key:** An SSH public/private key pair configured. The `terraform.tf` script expects the public key at `/home/idk/.ssh/id_rsa.pub` on the Proxmox host. The Bash script uses the private key at `/home/idk/.ssh/id_rsa` for Ansible connections to the LXC container. **Ensure these paths are correct for your setup.**
  * **Required Terraform Provider:** The `Telmate/proxmox` provider for Terraform.
  * **Network Access:** Ensure your local machine can reach the Proxmox API URL and the provisioned LXC container.

-----

### Security Considerations & Sensitive Data Handling

**It is CRUCIAL to understand how sensitive information is handled in this project, especially for production environments:**

  * **Hardcoded Placeholders:** The provided Terraform script (`Terraform/.tf`) and MariaDB Ansible playbook (`ansible/03-MariaDB.yml`) contain **placeholder values** for sensitive information (e.g., `IP.Address`, `username`, `password`, `root_db_password`).
      * **NEVER** hardcode actual passwords or sensitive IPs directly into your `main.tf` or Ansible playbooks when deploying to a real environment.
  * **Bash Script `PROXMOX_IP`:** The `Skript.sh` requires you to manually set `PROXMOX_IP`. This should be replaced with your Proxmox server's IP address.
  * **Recommended Secure Practices (for Production):**
      * **Terraform Variables:** Use [Terraform variables](https://developer.hashicorp.com/terraform/language/values/variables) to pass sensitive values during runtime (e.g., via environment variables like `TF_VAR_your_variable` or interactive prompts).
      * **.tfvars files (Excluded from Git):** If using `.tfvars` files, ensure `terraform.tfvars` (and similar files) are listed in your `.gitignore` to prevent committing sensitive data.
      * **Ansible Vault:** For sensitive data in Ansible playbooks (like `root_db_password` in `03-MariaDB.yml`), use [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to encrypt these values.
      * **Proxmox API Tokens:** For increased security, configure and use [Proxmox API tokens](https://www.google.com/search?q=https://pve.proxmox.com/pve-docs/api-viewer/%23/access/token) instead of username/password authentication in the Terraform `proxmox` provider.
      * **SSH Key Management:** Ensure your SSH private key (`/home/idk/.ssh/id_rsa`) is securely stored and protected.

-----

### Project Structure

```
.
├── ansible/
│   ├── 01-Preinstall.yml             # Installs basic packages (wget, git, unzip, etc.)
│   ├── 02-PHP-7.4.yml                # Installs PHP 7.4 and extensions (legacy option)
│   ├── 02-PHP-8.1.yml                # Installs PHP 8.1 and extensions (default)
│   ├── 03-MariaDB.yml                # Installs MariaDB server and client, sets up root password
│   ├── 04-iTop-3.1.1.yml             # Installs iTop 3.1.1 (legacy option)
│   ├── 04-iTop-3.1.2.yml             # Installs iTop 3.1.2 (legacy option)
│   ├── 04-iTop-3.2.0.yml             # Installs iTop 3.2.0 (default)
│   ├── 04-iTop-3.2.0-2.yml           # Installs iTop 3.2.0-2 (legacy option)
│   └── 05-Toolkit.yml                # Downloads and extracts iTop Toolkit
├── Skript.sh                         # Main Bash script to orchestrate Terraform and Ansible
├── Terraform/
│   └── .tf                           # Terraform configuration for Proxmox LXC creation
├── .gitignore                        # Specifies intentionally untracked files to ignore
└── README.md                         # This file
└── LICENSE                           # MIT License for the project
```

-----

### Setup and Usage

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YourUsername/Terraform-Ansible-Deployment.git
    cd Terraform-Ansible-Deployment
    ```
2.  **Navigate to the Terraform directory and initialize:**
    ```bash
    cd Terraform/
    terraform init
    ```
    **Note:** If using variables for sensitive data, ensure they are set now (e.g., via environment variables or a `.tfvars` file that you will NOT commit).
    ```bash
    cd .. # Go back to the root directory
    ```
3.  **Edit `Skript.sh`:**
      * Open `Skript.sh` and replace `PROXMOX_IP="..."` with the actual IP address of your Proxmox server.
      * Ensure the paths to your SSH private key (`/home/idk/.ssh/id_rsa`) are correct within `Skript.sh` and the Terraform configuration.
      * **Important:** Review the commented-out Ansible playbooks in `Skript.sh`. Uncomment the specific PHP and iTop versions you wish to install. By default, PHP 8.1 and iTop 3.2.0 are chosen.
4.  **Run the main deployment script:**
    ```bash
    chmod +x Skript.sh
    ./Skript.sh
    ```
    The script will:
      * Run `terraform apply` to create the LXC container.
      * Obtain the LXC's VMID and IP address.
      * Start the LXC via SSH.
      * Dynamically update `ansible/hosts.ini` with the new LXC IP.
      * Execute the selected Ansible playbooks to install and configure software.
      * Rename the LXC container.
      * Output the final IP address of the deployed iTop instance.

-----

### After Deployment

  * Once the script completes, you can access your iTop instance via the displayed IP address in your web browser. You will then need to complete the iTop web-based installation wizard.
  * Remember to clean up your `ansible/hosts.ini` file if you run the script multiple times, or consider adding logic to `Skript.sh` to remove old entries before adding new ones.

-----

## 🇨🇿 Nasazení a konfigurace iTopu na Proxmox LXC kontejnerech

Tento projekt poskytuje sadu skriptů **Infrastructure as Code (IaC)**, které využívají **Terraform** pro zřizování LXC kontejnerů v Proxmoxu a **Ansible** pro automatizovanou instalaci a konfiguraci softwaru. Primárním cílem je efektivně a opakovaně nasadit a nastavit instanci **iTop** (IT Operations Portal) v prostředí Proxmox Virtual Environment.

Tento projekt byl vyvinut jako moje **Absolventská práce** na **Vyšší odborné škole**.

-----

### Vlastnosti

  * **Zřizování Proxmox LXC:** Automaticky vytváří Debian 12 LXC kontejner na Proxmoxu pomocí Terraformu.
  * **Automatizovaná instalace softwaru:** Instaluje a konfiguruje nezbytné komponenty včetně:
      * **PHP:** Instaluje PHP (výchozí verze 8.1, s možností 7.4) a základní rozšíření pro iTop.
      * **Apache2:** Nastaví webový server Apache.
      * **MariaDB:** Instaluje MariaDB 11.5, konfiguruje root heslo a nastaví vzdálený přístup.
      * **iTop CMDB:** Stáhne a nasadí iTop (výchozí verze 3.2.0, s možnostmi 3.1.1, 3.1.2) na webový server.
      * **iTop Toolkit:** Nainstaluje iTop Toolkit pro poinstalační úkoly.
  * **Dynamické zpracování IP adres:** Automaticky získá IP adresu LXC a přidá ji do souboru s inventářem Ansible.
  * **Přejmenování kontejneru:** Přejmenuje vytvořený LXC kontejner na základě nainstalovaných verzí PHP a iTop pro lepší identifikaci.
  * **Přizpůsobitelné:** Snadno přizpůsobitelné pro různé verze PHP a iTop odkomentováním příslušných Ansible playbooků.

-----

### Předpoklady

Před spuštěním těchto skriptů se ujistěte, že máte následující:

  * **Proxmox VE Server:** Spuštěný Proxmox Virtual Environment.
  * **SSH Přístup k Proxmoxu:** Root SSH přístup k vašemu Proxmox hostiteli. Bash skript používá `ssh root@$PROXMOX_IP`.
  * **Terraform:** [Terraform](https://www.terraform.io/downloads.html) nainstalovaný na vašem lokálním počítači.
  * **Ansible:** [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) nainstalovaný na vašem lokálním počítači.
  * **SSH klíč:** Nakonfigurovaný pár veřejného/privátního SSH klíče. Skript `terraform.tf` očekává veřejný klíč na `/home/idk/.ssh/id_rsa.pub` na Proxmox hostiteli. Bash skript používá privátní klíč na `/home/idk/.ssh/id_rsa` pro připojení Ansible ke kontejneru LXC. **Ujistěte se, že tyto cesty jsou pro vaši konfiguraci správné.**
  * **Požadovaný Terraform provider:** Provider `Telmate/proxmox` pro Terraform.
  * **Síťový přístup:** Ujistěte se, že váš lokální počítač může dosáhnout API URL Proxmoxu a zřízeného kontejneru LXC.

-----

### Bezpečnostní aspekty a nakládání s citlivými daty

**Je KLÍČOVÉ pochopit, jak se s citlivými informacemi v tomto projektu zachází, zejména pro produkční prostředí:**

  * **Zástupné hodnoty (Placeholdery):** Poskytnutý Terraform skript (`Terraform/.tf`) a Ansible playbook pro MariaDB (`ansible/03-MariaDB.yml`) obsahují **zástupné hodnoty** pro citlivé informace (např. `IP.Address`, `username`, `password`, `root_db_password`).
      * **NIKDY** nekódujte skutečná hesla nebo citlivé IP adresy přímo do `main.tf` nebo Ansible playbooků při nasazování do reálného prostředí.
  * **Bash Skript `PROXMOX_IP`:** Skript `Skript.sh` vyžaduje ruční nastavení `PROXMOX_IP`. Toto by mělo být nahrazeno skutečnou IP adresou vašeho Proxmox serveru.
  * **Správa SSH klíčů:** Ujistěte se, že váš privátní SSH klíč (`/home/idk/.ssh/id_rsa`) je bezpečně uložen a chráněn.
  * **Doporučené bezpečné postupy (pro produkci):**
      * **Terraform Proměnné:** Použijte [Terraform proměnné](https://developer.hashicorp.com/terraform/language/values/variables) pro předávání citlivých hodnot za běhu (např. prostřednictvím proměnných prostředí jako `TF_VAR_your_variable` nebo interaktivních dotazů).
      * **.tfvars soubory (vyřazené z Gitu):** Pokud používáte soubory `.tfvars`, ujistěte se, že `terraform.tfvars` (a podobné soubory) jsou uvedeny ve vašem `.gitignore`, abyste zabránili odesílání citlivých dat.
      * **Ansible Vault:** Pro citlivá data v Ansible playbookách (jako `root_db_password` v `03-MariaDB.yml`) použijte [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) k zašifrování těchto hodnot.
      * **Proxmox API Tokeny:** Pro zvýšení bezpečnosti nakonfigurujte a použijte [Proxmox API tokeny](https://www.google.com/search?q=https://pve.proxmox.com/pve-docs/api-viewer/%23/access/token) namísto ověřování uživatelským jménem a heslem v provideru `proxmox` Terraformu.

-----

### Struktura projektu

```
.
├── ansible/
│   ├── 01-Preinstall.yml             # Instaluje základní balíčky (wget, git, unzip, atd.)
│   ├── 02-PHP-7.4.yml                # Instaluje PHP 7.4 a rozšíření (starší možnost)
│   ├── 02-PHP-8.1.yml                # Instaluje PHP 8.1 a rozšíření (výchozí)
│   ├── 03-MariaDB.yml                # Instaluje MariaDB server a klienta, nastaví root heslo
│   ├── 04-iTop-3.1.1.yml             # Instaluje iTop 3.1.1 (starší možnost)
│   ├── 04-iTop-3.1.2.yml             # Instaluje iTop 3.1.2 (starší možnost)
│   ├── 04-iTop-3.2.0.yml             # Instaluje iTop 3.2.0 (výchozí)
│   ├── 04-iTop-3.2.0-2.yml           # Instaluje iTop 3.2.0-2 (starší možnost)
│   └── 05-Toolkit.yml                # Stáhne a rozbalí iTop Toolkit
├── Skript.sh                         # Hlavní Bash skript pro orchestraci Terraformu a Ansible
├── Terraform/
│   └── .tf                           # Terraform konfigurace pro vytvoření Proxmox LXC
├── .gitignore                        # Specifikuje soubory, které se nemají sledovat Gitem
└── README.md                         # Tento soubor
└── LICENSE                           # MIT Licence pro projekt
```

-----

### Nastavení a použití

1.  **Klonování repozitáře:**
    ```bash
    git clone https://github.com/YourUsername/Terraform-Ansible-Deployment.git
    cd Terraform-Ansible-Deployment
    ```
2.  **Přechod do adresáře Terraform a inicializace:**
    ```bash
    cd Terraform/
    terraform init
    ```
    **Poznámka:** Pokud používáte proměnné pro citlivá data, ujistěte se, že jsou nyní nastaveny (např. prostřednictvím proměnných prostředí nebo souboru `.tfvars`, který NEBUDETE commitovat).
    ```bash
    cd .. # Zpět do kořenového adresáře
    ```
3.  **Úprava `Skript.sh`:**
      * Otevřete `Skript.sh` a nahraďte `PROXMOX_IP="..."` skutečnou IP adresou vašeho Proxmox serveru.
      * Ujistěte se, že cesty k vašemu privátnímu SSH klíči (`/home/idk/.ssh/id_rsa`) jsou správné ve skriptu `Skript.sh` a v konfiguraci Terraformu.
      * **Důležité:** Zkontrolujte zakomentované Ansible playbooky ve skriptu `Skript.sh`. Odkomentujte konkrétní verze PHP a iTopu, které chcete nainstalovat. Ve výchozím nastavení jsou vybrány PHP 8.1 a iTop 3.2.0.
4.  **Spuštění hlavního nasazovacího skriptu:**
    ```bash
    chmod +x Skript.sh
    ./Skript.sh
    ```
    Skript provede:
      * Spustí `terraform apply` pro vytvoření LXC kontejneru.
      * Získá VMID a IP adresu LXC.
      * Spustí LXC přes SSH.
      * Dynamicky aktualizuje soubor `ansible/hosts.ini` s novou IP adresou LXC.
      * Spustí vybrané Ansible playbooky pro instalaci a konfiguraci softwaru.
      * Přejmenuje LXC kontejner.
      * Vypíše konečnou IP adresu nasazené instance iTop.

-----

### Po nasazení

  * Jakmile skript dokončí, můžete přistupovat k vaší instanci iTop pomocí zobrazené IP adresy ve vašem webovém prohlížeči. Poté budete muset dokončit webového průvodce instalací iTopu.
  * Nezapomeňte vyčistit soubor `ansible/hosts.ini`, pokud skript spustíte vícekrát, nebo zvažte přidání logiky do `Skript.sh` pro odstranění starých záznamů před přidáním nových.

-----
