# Nutri-bit Mobile

Aplicativo Flutter/Dart que utiliza o mesmo back-end NestJS/Prisma do Nutri-bit e reproduz a identidade do front-end web e do PDF Link Figma. O código de interface e integração está em Dart; Android e Windows usam os arquivos de plataforma gerados pelo Flutter.

## Pré-requisitos
- Flutter SDK compatível com Dart ^3.12.2 (restrição do projeto recebido), VS Code ou Android Studio.
- Android Studio com SDK e emulador para Android; Visual Studio com Desktop development with C++ para Windows (não confundir com VS Code).
- Node.js e o back-end original.

## 1. Inicie o back-end original
No terminal, na pasta `Nutri-bit-backapp-master`:

```powershell
npm install
npx prisma generate
npm run start:dev
```

O back-end original contém banco SQLite. Preserve uma cópia do banco e do arquivo de configuração existente. Se for usar banco novo, consulte o README original para migrações e importação da TBCA/modelos. Não é necessário executar o front-end Next.js para usar o mobile.

## 2. Abra o projeto mobile
Extraia o ZIP em uma pasta nova e abra `nutri_bit_mobile` no VS Code ou Android Studio. As pastas nativas e `.metadata` são as do projeto Flutter fornecido. Não execute `flutter create` nem `preparar.ps1`.

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Os caches locais, arquivos de IDE e caminhos absolutos de SDK foram removidos; o Flutter os recria. O manifesto Android já está configurado para acessar a API local. Se o PATH estiver incompleto no Windows, execute no mesmo terminal antes dos comandos acima:

```powershell
$env:Path += ";C:\Windows;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;C:\Program Files\Git\cmd"
```

## 3. Execute
Windows:
```powershell
flutter run -d windows
```
Android: abra o Device Manager do Android Studio, inicie o emulador, depois:
```powershell
flutter devices
flutter run -d emulator-5554
```
Troque `emulator-5554` pelo ID exibido no seu computador. Também pode abrir o projeto no Android Studio, selecionar o emulador e executar `lib/main.dart` com os plugins Flutter/Dart.

### Endereço da API
- Windows: `http://localhost:3000/api`
- Emulador Android: `http://10.0.2.2:3000/api`
- Celular físico: use o IP local do computador na mesma rede (libere a porta 3000 no firewall para rede privada, se necessário):
```powershell
flutter run --dart-define=API_URL=http://192.168.1.100:3000/api
```
Substitua pelo IP real. HTTP é somente para desenvolvimento local; para produção use HTTPS e remova a permissão de cleartext. A fonte Archivo é carregada pelo pacote google_fonts (pode precisar de internet na primeira execução). Se a rede bloquear a fonte, execute `flutter run -d windows --dart-define=OFFLINE_FONT=true` (ou troque o dispositivo pelo Android) para utilizar a fonte padrão sem download.

## Funcionalidades
- Apresentação, login, cadastro, objetivo e logout.
- Perfil editável, avatar por URL e meta calórica calculada pelo back-end.
- Planos sugeridos, perfil incompleto, criação, edição, exclusão, plano ativo/inativo.
- Semanas, dias, refeições, ingredientes, busca TBCA, substituições equivalentes, totais diários.
- Painel administrativo, usuários e perfis (restritos a contas com role admin no servidor). O servidor não oferece troca de senha via PUT /users/:id; o formulário de edição só muda nome/e-mail. Para cadastrar usuário, uma senha é exigida pelo DTO, ainda que não apareça no mockup.
- Sessão JWT em memória: fechar o aplicativo exige novo login. 401 encerra a sessão.

## Estrutura
```
lib/
  main.dart          # Aplicativo, tema e navegação
  models/data.dart   # Tipos JSON, opções e formatação
  services/api.dart  # HTTP, JWT e sessão
  widgets/ui.dart    # Componentes compartilhados e tema
  screens/auth.dart
  screens/profile.dart
  screens/plans.dart
  screens/meal.dart
  screens/admin.dart
```

Dependências: Flutter, flutter_localizations, http e google_fonts. Não há React, Next.js, HTML, CSS ou JavaScript no mobile. Os arquivos nativos gerados automaticamente podem incluir Kotlin, Gradle e C++.

## Validação
```powershell
flutter analyze
flutter test
```
Testes incluídos para login HTTP 201, JWT, cadastro, expiração da sessão, formatação e apresentação responsiva. O SDK Flutter não estava disponível no ambiente de criação deste ZIP, então os testes e a compilação ainda precisam ser executados localmente. Não foi feito teste de ponta a ponta com o back-end em execução.

Roteiro manual: cadastrar conta -> escolher objetivo -> preencher perfil -> abrir sugestões -> criar plano -> adicionar semana -> adicionar refeição -> pesquisar alimento -> inserir quantidade -> salvar -> conferir totais -> editar/excluir refeição. Para administrador, entrar com conta admin existente no banco e testar CRUD de usuários/perfis.

## Revisão de codificação
Os arquivos Dart foram restaurados em UTF-8, sem BOM. A API envia e decodifica JSON explicitamente em UTF-8. Foi adicionada cobertura de regressão para textos e dados com acentos. Também foram adicionadas verificações de `mounted` nos dois pontos indicados pelo analisador e uma mensagem de erro na busca de substituições. No VS Code, mantenha a codificação UTF-8. Não utilize `Get-Content`/`Set-Content` sem especificar a codificação no Windows PowerShell.

Esta revisão foi conferida estaticamente; execute `flutter analyze`, `flutter test` e `flutter run` no computador com o SDK.

## Tipos de opções (mobile)
No detalhe do plano, cada ingrediente tem o botão **Tipos de opções**, que abre uma consulta sem mudar a refeição. Na edição ou criação da refeição, o mesmo botão permite escolher **Trocar** e salvar a refeição normalmente. Remover é uma ação separada com confirmação.

A consulta usa `GET /foods/:id/similar` já existente. Para arroz e tubérculos, o mobile também procura alternativas cozidas ou assadas em `GET /foods?search=...` e calcula a quantidade aproximada pelo valor energético por 100 g. Não são incluídos nas opções extras itens crus, fritos ou sem calorias cadastradas. Exemplo do banco fornecido: 100 g de arroz polido cozido (131 kcal) correspondem a aproximadamente 90 g de batata-doce assada (130,5 kcal). O banco possui batata cozida sem calorias cadastradas, por isso não é oferecida como opção extra. Equivalência calórica não significa equivalência de todos os nutrientes. Nenhuma alteração no back-end ou no front-end web foi necessária.

Teste manual: abrir um plano com arroz -> Tipos de opções -> conferir porções -> fechar sem alterar -> Editar refeição -> Tipos de opções -> Trocar -> Salvar refeição -> conferir totais. O teste `test/food_options_test.dart` usa respostas simuladas da API. Compilação, análise e execução dos testes ainda precisam ser feitas com o SDK Flutter local.
