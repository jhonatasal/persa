# persa

CLI extensível para gerenciamento de processos e ambientes de desenvolvimento.

Funciona em **macOS**, **Linux** e **Windows**.

---

## Instalação

### macOS / Linux

```sh
git clone git@github.com:jhonatasal/persa.git
cd persa
sh install.sh
source ~/.zshrc   # ou ~/.bashrc
```

### Windows (PowerShell)

```powershell
git clone git@github.com:jhonatasal/persa.git
cd persa
.\install.ps1
. $PROFILE
```

> Se encontrar erro de execution policy:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## Uso

```sh
persa --help
persa <modulo> --help
```

### Módulo `port`

```sh
persa port 3000               # verifica se a porta está em uso
persa port kill 3000          # mata o processo que usa a porta
```

### Módulo `docker`

```sh
persa docker clean images             # lista imagens e pede confirmação
persa docker clean images --force     # remove sem pedir confirmação
```

---

## Atualizar

```sh
persa update
```

Sincroniza a instalação com a versão mais recente do repositório local.

---

## Trocar o nome da CLI

Edite `cli.conf` e rode o instalador novamente:

```sh
# cli.conf
CLI_NAME="minha_cli"
```

```sh
sh install.sh
source ~/.zshrc
```

---

## Arquitetura

O projeto segue os princípios do **Clean Architecture**, organizado em camadas com dependência sempre de fora para dentro:

```
persa/
├── cli.conf                        # nome e versão da CLI
├── persa.sh                        # entry point Unix
├── persa.ps1                       # entry point Windows (self-contained)
├── install.sh / uninstall.sh       # instaladores Unix
├── install.ps1 / uninstall.ps1     # instaladores Windows
└── src/
    ├── ui/
    │   └── output.sh               # constantes de cor (ANSI)
    ├── infra/
    │   ├── port_unix.sh            # lsof / ps / kill (Unix)
    │   └── docker_unix.sh          # docker CLI wrappers (Unix)
    └── commands/
        ├── port.sh                 # lógica do módulo port
        └── docker.sh               # lógica do módulo docker
```

| Camada | Responsabilidade |
|---|---|
| `ui/` | Definição de cores, sem lógica de negócio |
| `infra/` | Chamadas ao sistema operacional e ferramentas externas |
| `commands/` | Orquestra infra + formata saída para o usuário |
| Entry point | Roteamento de módulos, `update`, `--help` |

A camada `commands` não chama `lsof`, `docker` ou `kill` diretamente — isso é responsabilidade da `infra`. Isso facilita trocar a implementação por plataforma sem tocar na lógica dos comandos.

---

## Adicionar um novo módulo

1. Crie `src/infra/<modulo>_unix.sh` com as funções de sistema
2. Crie `src/commands/<modulo>.sh` com os handlers do comando
3. Em `persa.sh`: adicione os `source` e o `case` no `_persa_main`
4. Em `install.sh`: adicione os `cp` dos novos arquivos
5. *(Windows)* Em `persa.ps1`: adicione as funções nas seções correspondentes

---

## Desinstalar

### macOS / Linux

```sh
sh uninstall.sh
source ~/.zshrc
```

### Windows

```powershell
.\uninstall.ps1
. $PROFILE
```
