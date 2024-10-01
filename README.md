# FIAP - SOAT7 🚀

## Team 95 - Delivery Now

```
🍔 System Fast Food
```

---

## | 👊🏽 • Team 95

|     | Name           | Identity |
| --- | -------------- | -------- |
| 🐰  | Leandro Coelho | RM355527 |

---

## | 🖥️ • Event Storming

- https://miro.com/miroverse/sistema-de-delivery/?social=copy-link

## | ✉️ • Lambda: Autenticação com AWS Cognito

Esta AWS Lambda faz parte do sistema de delivery "deliverynow" e é responsável por autenticar usuários via AWS Cognito. Ela é acionada através do AWS API Gateway, que recebe as solicitações e as encaminha para a Lambda. A Lambda realiza a autenticação dos usuários utilizando o serviço de identidade do Cognito, validando os tokens de acesso e garantindo que apenas usuários autenticados possam acessar os recursos protegidos do sistema.

### Funcionalidades:

- Recebe solicitações via AWS API Gateway.
- Integração com AWS Cognito para autenticação de usuários.
- Valida tokens JWT emitidos pelo Cognito.
- Retorna respostas apropriadas de sucesso ou erro com base na validação do token.

### Fluxo:

1. O usuário realiza uma requisição para o Gateway.
2. A Lambda recebe a requisição e utiliza o Cognito para autenticar o usuário.
3. Após a validação, a Lambda retorna uma resposta indicando o sucesso ou falha da autenticação.
