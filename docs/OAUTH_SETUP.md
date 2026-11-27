# Login com Google e Microsoft (OAuth 2.0 + PKCE + OIDC)

Este documento explica como criar as credenciais e configurar o login social do SOMASE.
O fluxo é implementado em PHP puro (`app/Services/OAuthService.php`), sem Composer:

- **Authorization Code + PKCE (S256)** — o `code_verifier` fica na sessão e nunca trafega na URL.
- **`state`** aleatório de 32 bytes, comparado com `hash_equals()` para evitar CSRF no callback.
- **OpenID Connect** — o `id_token` é lido para obter `sub`, `email`, `email_verified`, `name` e `picture`.
- **cURL** com `CURLOPT_SSL_VERIFYPEER`/`VERIFYHOST` ligados e timeout de 10 segundos.
- Tokens de acesso **não são gravados** em log nem em banco; apenas o `sub` do provedor é salvo em `user_identities`.

> Enquanto `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` (ou o par equivalente da Microsoft) não estiverem
> preenchidos no `.env`, os botões **desaparecem** da tela de login automaticamente.
> Se alguém acessar `/auth/google` diretamente, o sistema volta para `/login` com a mensagem
> "Login com Google indisponível no momento." e registra a tentativa em `auth_attempts`.

---

## 1. Variáveis de ambiente

No arquivo `.env` (na raiz do projeto, ao lado de `app/`):

```ini
APP_URL=https://finance.minasbyte.com

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

MICROSOFT_CLIENT_ID=
MICROSOFT_CLIENT_SECRET=
# common = contas pessoais + trabalho/escola; use o Tenant ID para restringir a uma empresa
MICROSOFT_TENANT=common
```

Depois de alterar o `.env`, não é preciso reiniciar nada: o arquivo é lido a cada requisição.

### URIs de redirecionamento

Cadastre **exatamente** estas URLs no console de cada provedor (sem barra no final):

| Ambiente | Google / Microsoft |
| --- | --- |
| Produção | `https://finance.minasbyte.com/auth/google/callback` |
| Produção | `https://finance.minasbyte.com/auth/microsoft/callback` |
| Local | `http://localhost:8000/auth/google/callback` |
| Local | `http://localhost:8000/auth/microsoft/callback` |

> O Google aceita `http://localhost` para desenvolvimento. A Microsoft também aceita `http://localhost`,
> mas **exige** que a URI seja cadastrada na plataforma "Web" do aplicativo.

O sistema monta a URI de retorno a partir de `APP_URL`. Se `APP_URL` estiver vazio, ou apontar para
`localhost` enquanto a requisição chega por outro domínio, ele usa o host da requisição
(`https://` + `HTTP_HOST`). Para produção, prefira sempre deixar `APP_URL` explícito.

---

## 2. Google Cloud Console

1. Acesse <https://console.cloud.google.com/> e selecione (ou crie) um projeto — sug.: `SOMASE Finance`.
2. Menu **APIs e serviços → Tela de consentimento OAuth**:
   - Tipo de usuário: **Externo** (ou Interno, se usar Google Workspace da empresa).
   - Nome do app: `SOMASE — Controle Financeiro`.
   - E-mail de suporte e e-mail do desenvolvedor: um endereço monitorado.
   - Domínios autorizados: `minasbyte.com`.
   - Escopos: apenas `openid`, `email` e `profile` (o SOMASE não pede nada além disso).
   - Publique o app (em "Teste" só funcionam os e-mails cadastrados como testadores).
3. Menu **APIs e serviços → Credenciais → Criar credenciais → ID do cliente OAuth**:
   - Tipo: **Aplicativo da Web**.
   - Nome: `SOMASE Web`.
   - **URIs de redirecionamento autorizados**:
     - `https://finance.minasbyte.com/auth/google/callback`
     - `http://localhost:8000/auth/google/callback`
   - **Origens JavaScript autorizadas**: não é necessário (o fluxo é server-side).
4. Copie o **ID do cliente** e a **Chave secreta do cliente** para `GOOGLE_CLIENT_ID` e
   `GOOGLE_CLIENT_SECRET` no `.env`.
5. Teste em `/login`: o botão "Continuar com Google" passa a aparecer.

---

## 3. Microsoft Entra ID (Azure AD)

1. Acesse <https://entra.microsoft.com/> → **Aplicativos → Registros de aplicativo → Novo registro**.
2. Nome: `SOMASE — Controle Financeiro`.
3. Tipos de conta com suporte:
   - `Contas em qualquer diretório organizacional e contas pessoais da Microsoft` → use `MICROSOFT_TENANT=common`.
   - Somente a sua empresa → use o **ID do diretório (tenant)** em `MICROSOFT_TENANT`.
4. **URI de redirecionamento**: plataforma **Web** →
   `https://finance.minasbyte.com/auth/microsoft/callback`
   (e `http://localhost:8000/auth/microsoft/callback` para testes locais).
5. Em **Certificados e segredos → Segredos do cliente → Novo segredo do cliente**:
   - Descrição: `SOMASE Web`; validade: 24 meses (anote a data de expiração no calendário).
   - Copie o **Valor** imediatamente (ele não é exibido de novo) para `MICROSOFT_CLIENT_SECRET`.
6. Em **Visão geral**, copie o **ID do aplicativo (cliente)** para `MICROSOFT_CLIENT_ID`.
7. Em **Permissões de API**, confirme `openid`, `email`, `profile`, `User.Read` (Microsoft Graph).
   Se a organização exigir consentimento do administrador, peça a aprovação em
   **Permissões de API → Conceder consentimento do administrador**.
8. Teste em `/login`: o botão "Continuar com Microsoft" passa a aparecer.

---

## 4. Como o sistema decide o que fazer no callback

1. Valida `state` (sessão) e troca o `code` por tokens usando o `code_verifier`.
2. Recusa e-mail **não verificado** pelo provedor (`email_verified`/`verified_primary_email`).
3. Procura o vínculo em `user_identities` (`provider` + `provider_user_id` = `sub`):
   - **Encontrou** → faz login (respeitando `status = inactive`).
   - **Não encontrou**, mas existe `users.email` igual → cria o vínculo e faz login.
   - **Não encontrou nada** → cria usuário com senha aleatória, perfil `user`, `auth_provider`,
     `avatar_url` e `email_verified_at`, e envia para `/cadastro/completar`.
4. Enquanto `birth_date` ou `terms_accepted_at` estiverem vazios, o usuário só acessa
   `/cadastro/completar`, `/termos`, `/privacidade` e `/logout`. Contas administrativas são isentas.
5. Toda falha volta para `/login` com mensagem amigável e é registrada em `auth_attempts` e `audit_logs`.

---

## 5. Problemas comuns

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| Botão não aparece | `CLIENT_ID`/`CLIENT_SECRET` vazios no `.env` | Preencher as duas variáveis |
| `redirect_uri_mismatch` (Google) | URI diferente da cadastrada | Cadastrar exatamente a URL do callback, sem barra final |
| `AADSTS50011` (Microsoft) | Redirect URI não cadastrada na plataforma **Web** | Cadastrar em "URIs de redirecionamento" → Web |
| "Não foi possível validar a sessão" | Cookie de sessão perdido entre ida e volta (bloqueio de cookies, troca de domínio) | Acessar sempre pelo mesmo domínio (`https://` sem `www` extra) |
| "E-mail não verificado no provedor" | Conta sem e-mail verificado | Verificar a conta no provedor |
| "Sua conta está desativada" | `users.status = inactive` | Reativar em `/admin/usuarios` |

---

## 6. Segurança — checklist

- [x] PKCE S256 em todos os fluxos (nada de `client_secret` no navegador).
- [x] `state` de uso único, comparado com `hash_equals()`.
- [x] `client_secret` só existe no `.env` (nunca no repositório, nunca no HTML).
- [x] TLS verificado nas chamadas de token/userinfo; timeout de 10 s.
- [x] Tokens não são persistidos nem logados.
- [x] E-mail do provedor precisa estar verificado.
- [x] Sessão regenerada no login (`session_regenerate_id(true)`).
- [ ] Rotacionar o segredo da Microsoft antes do vencimento.
- [ ] Revisar os apps autorizados periodicamente no console do provedor.
