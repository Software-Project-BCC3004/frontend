# Frontend PEWS - Sistema de Monitoramento Pediátrico

![Uploading PEWS_2025.gif…]()

## Pré-requisitos

- Flutter SDK instalado e configurado
- Git instalado
- Backend do projeto em execução

## Configuração do Backend

Antes de executar o frontend, é necessário configurar e iniciar o backend:

1. Clone o repositório do backend:
   ```
   git clone https://github.com/Software-Project-BCC3004/backend.git
   ```

2. Siga as instruções no README do backend para configurar e iniciar o servidor:
   - Instale Java e Maven
   - Configure o banco de dados MySQL
   - Execute o projeto com `mvn spring-boot:run`
   - Verifique se o backend está rodando em `http://localhost:8080`

## Configuração do Frontend

1. Clone o repositório do frontend (caso ainda não tenha feito)

2. Navegue até o diretório do projeto:
   ```
   cd frontend
   ```

3. Instale as dependências:
   ```
   flutter pub get
   ```

4. Execute o aplicativo no Chrome com as flags necessárias para permitir requisições cross-origin:
   ```
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```

## Observações Importantes

- O backend deve estar em execução antes de iniciar o frontend
- A aplicação está configurada para se conectar ao backend em `http://localhost:8080`
- Caso o backend esteja em outro endereço, atualize a URL base nos arquivos de serviço

## Solução de Problemas

- Se ocorrerem erros de CORS, verifique se o frontend está sendo executado com a flag `--disable-web-security`
- Para problemas de conexão com o backend, verifique se o servidor está em execução e acessível



Vai Corinthians
