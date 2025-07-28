#  Limpeza automática do Docker

Este script automatiza a limpeza de recursos no utilizados pelo Docker como: imagens, containers, volumes e cache, ideal para ambientes com uso frequente do Docker.

---

##  Exemplo de cenário de uso

Use este script quando:

-  Você usa Docker com frequência, mas remove recursos manualmente.
-  Está ficando sem espaço em disco ou possui espaço limitado.
-  Tem muitos containers parados e logs pesados.
-  Seu servidor executa builds automáticos com Docker (CI/CD).
-  Deseja automatizar a limpeza de forma segura.

**Uso não recomendado:**  
> Se você precisa manter imagens, volumes ou containers antigos.

---

##  ⚠️ Atenção

O script **remove tudo que o Docker considera no utilizado**, incluindo:

-  Containers parados
-  Imagens no referenciadas
-  Volumes
-  Cache de build
-  Logs dos containers

 **Se você utiliza volumes persistentes com dados importantes, revise antes de executar!**

---

##  O que o script faz?

### 1 Verificação de agendamento
Recebe um argumento `OnCalendar` para definir quando o timer ser executado.

Exemplo:
```bash
./install-docker-cleanup.sh "Sun *-*-* 03:00:00"
```

### 2 Criação do script de limpeza

Cria `/usr/local/bin/docker-deep-clean.sh`, que:

- Exibe o espaço livre antes e depois da limpeza.
- Executa:
  - `docker system prune -af --volumes`
  - `docker builder prune -af`
- Zera arquivos `.log` em `/var/lib/docker/containers/`.

### 3 Criação do serviço systemd

Cria `/etc/systemd/system/docker-deep-clean.service` com:

- Tipo `oneshot` (executa uma vez).
- Executa o script de limpeza.

### 4 Criação do timer systemd

Cria `/etc/systemd/system/docker-deep-clean.timer` com:

- Agendamento `OnCalendar=$SCHEDULE`
- `Persistent=true` para executar mesmo se o sistema estiver desligado na hora agendada.

### 5 Ativação

Recarrega systemd e ativa o timer:

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now docker-deep-clean.timer
```

---

##  Como testar o script

###  Requisitos

- Acesso `root` ou `sudo`
- Docker instalado
- Systemd disponvel (ex: Ubuntu, Debian, Fedora)

###  Opção 1: Com uma imagem Docker

1. Rode uma imagem:
```bash
docker run -it ubuntu bash
```
Para este teste estou executando a imagem ubuntu bash

2. Salve o instalador:
```bash
nano install-docker-cleanup.sh
```

3. Dê permissão:
```bash
chmod +x install-docker-cleanup.sh
```

4. Execute com agendamento para teste:
```bash
sudo ./install-docker-cleanup.sh "*-*-* *:*:00"
```
Isso agenda o timer para rodar a cada minuto (cenário para teste).

1. Verifique se o timer foi criado:
```bash
systemctl list-timers | grep docker-deep-clean
```

1. Verifique os logs:
```bash
journalctl -u docker-deep-clean.service
```

1. Rode manualmente, se quiser:
```bash
sudo /usr/local/bin/docker-deep-clean.sh
```

---

###  Dicas de agendamento `OnCalendar`

| Descrio                 | Expresso `OnCalendar`      |
|--------------------------|-----------------------------|
| Todo dia  meia-noite    | `daily`                     |
| Todo domingo às 3h       | `Sun *-*-* 03:00:00`        |
| Toda hora                | `hourly`                    |
| A cada minuto (teste)    | `*-*-* *:*:00`              |

---

###  Opção 2: Sem imagem Docker

Você pode testar o script mesmo sem containers ou imagens. Ele será executado, apenas não encontrará o que limpar.

```bash
sudo ./install-docker-cleanup.sh "*-*-* *:*:00"
```

Verifique com:
```bash
systemctl list-timers | grep docker-deep-clean
journalctl -u docker-deep-clean.service
```

---

##  Como parar a execução automática?

Desative o timer com:

```bash
sudo systemctl disable --now docker-deep-clean.timer
```
