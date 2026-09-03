# Google OAuth — ambiente de desenvolvimento EloEase

Este guia configura apenas desenvolvimento. Não promova o projeto para
produção enquanto Termos, Aviso de Privacidade, homepage e exclusão de conta
não estiverem aprovados.

## 1. Google Cloud

1. Crie um projeto separado de desenvolvimento e configure a marca como
   **EloEase**.
2. Defina a audiência como externa, em **Testing**, e adicione os e-mails de
   teste. Solicite somente `openid`, `email` e `profile`.
3. Crie o cliente Web. Ele será cadastrado no Supabase; o redirect é
   `https://<project-ref>.supabase.co/auth/v1/callback`.
4. Crie o cliente Android com package `br.com.myelolabs.eloease` e o SHA-1 do
   certificado debug. Adicione o SHA-1 de release somente quando ele existir.
5. Crie o cliente iOS com bundle `br.com.myelolabs.eloease`.

O Client Secret do Web client é segredo operacional: use apenas no dashboard
Supabase. Não o coloque em `local.json`, Xcode, GitHub Actions ou logs.

## 2. Supabase

1. No projeto de desenvolvimento, ative Google em Authentication > Providers.
2. Informe Web Client ID e Client Secret.
3. Para Google nativo no iOS, habilite **Skip nonce check** conforme a
   orientação do SDK Supabase.
4. Mantenha magic link desativado para este fluxo e não configure redirects
   `localhost` ou `beforeibuy://`.

## 3. Flutter

1. Em `apps/mobile`, copie `config/local.example.json` para `config/local.json`.
2. Preencha somente `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
   `GOOGLE_WEB_CLIENT_ID` e `GOOGLE_IOS_CLIENT_ID`.
3. Copie `ios/Flutter/GoogleSignIn.xcconfig.example` para
   `GoogleSignIn.xcconfig` e preencha o reversed iOS Client ID.
4. Execute com:

```bash
flutter run --dart-define-from-file=config/local.json
```

Não inclua senha Postgres, service role ou Client Secret no arquivo mobile.

## 4. Evidências antes do beta

- Android debug entra e recupera a sessão em reinício.
- Cancelar o seletor Google não altera rascunho nem abre publicação.
- Erro de credencial exibe somente a mensagem genérica do app.
- iOS será validado em macOS/dispositivo real antes de qualquer distribuição.
