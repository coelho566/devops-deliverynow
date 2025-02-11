# FIAP - SOAT7 🚀

## Team 95 - File Zip

```
🍔 System File Zip
```

---

## | 👊🏽 • Team 95

|     | Name           | Identity |
| --- | -------------- | -------- |
| 🐰  | Leandro Coelho | RM355527 |

---

## | 🖥️ • Event Storming

- https://miro.com/miroverse/sistema-de-delivery/?social=copy-link

# Infraestrutura AWS com Terraform

Este repositório contém a infraestrutura do projeto **File Zip**, configurada utilizando o Terraform. Ele inclui módulos para provisionamento dos principais recursos na AWS, necessários para suportar a aplicação.

## Módulos Principais

- **VPC**: Configuração de Virtual Private Cloud para gerenciar a rede da infraestrutura.
- **ECR**: Amazon Elastic Container Registry para armazenar as imagens de container Docker.
- **EKS**: Amazon Elastic Kubernetes Service para orquestração de containers, responsável por rodar os serviços da aplicação.
- **Cognito**: Gerenciamento de autenticação de usuários, com integração para o controle de acesso à API e Lambda.
- **Lambda**: Funções serverless para processar requisições e eventos.
- **API Gateway**: Exposição de APIs para comunicação com a aplicação e serviços externos.
- **Secrets Manager**: Armazenamento seguro de credenciais e informações sensíveis usadas pela aplicação.
- **Load Balancer**: Balanceamento de carga para distribuir o tráfego de rede entre os serviços do EKS.
- **Keycloak**: Serviço de autenticação e gerenciamento do usuário

## Estrutura do Repositório

O repositório está organizado de forma modular, permitindo fácil manutenção e reutilização dos componentes da infraestrutura.

Cada módulo pode ser gerenciado de forma independente, facilitando o controle de versão e o ciclo de vida dos recursos provisionados.

## Como Usar

1. Configure suas credenciais AWS.
2. Clone este repositório:

   ```bash
   git clone <url-do-repositorio>

   ```

3. Execute os comandos do Terraform para provisionar os recursos:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Requisitos

- Terraform >= 1.0.0
- AWS CLI configurado com as permissões adequadas
- Conta AWS válida com permissões para provisionamento de recursos
