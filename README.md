# Nutri-bit Mobile

## Membros do grupo

- André Hallwass
- Carlos Tortelli

## Nome do aplicativo

Nutri-bit Mobile

## Resumo do aplicativo

O Nutri-bit Mobile é um aplicativo desenvolvido em Flutter e Dart, com o objetivo de auxiliar os usuários no planejamento alimentar, na organização de refeições e no acompanhamento nutricional.

O aplicativo utiliza a mesma API REST e o mesmo banco de dados da versão web do Nutri-bit, permitindo a integração entre as plataformas.

## Tecnologias utilizadas

- **Flutter:** desenvolvimento multiplataforma.
- **Dart:** linguagem de programação.
- **NestJS:** desenvolvimento do back-end integrado ao aplicativo.
- **Prisma:** gerenciamento e acesso ao banco de dados.
- **SQLite:** armazenamento de dados.
- **JWT:** autenticação de usuários.
- **HTTP:** comunicação com a API REST.
- **Google Fonts:** padronização da tipografia.

## Funcionalidades

### Usuário

- Cadastro e autenticação.
- Gerenciamento do perfil.
- Definição de objetivos alimentares.
- Visualização da meta calórica.
- Sugestões de planos alimentares.
- Criação, edição e exclusão de planos.
- Organização de semanas, dias e refeições.
- Cadastro e gerenciamento de ingredientes.
- Consulta de alimentos da base TBCA.
- Acompanhamento de calorias e macronutrientes.
- Substituição de alimentos por opções equivalentes.

### Administrador

- Painel administrativo.
- Gerenciamento de usuários.
- Gerenciamento de perfis.
- Controle de acesso baseado nas permissões do usuário.

### Substituição alimentar

A funcionalidade **Tipos de opções** permite que o usuário consulte alimentos semelhantes e realize substituições de ingredientes com quantidades aproximadamente equivalentes em calorias.

Essa funcionalidade é exclusiva do aplicativo mobile e utiliza os dados nutricionais disponibilizados pelo back-end.

## Organização do código

- **models:** representação e tratamento dos dados.
- **services:** comunicação com a API, autenticação e substituição alimentar.
- **widgets:** componentes reutilizáveis e identidade visual.
- **screens:** telas e funcionalidades do aplicativo.
- **test:** testes automatizados.

## Plataformas

O aplicativo foi desenvolvido utilizando Flutter, permitindo a execução multiplataforma:

- Android
- iOS
- Windows
- Linux
- macOS
- Web

O projeto possui estrutura para todas essas plataformas, com foco principal na execução em Android e Windows.

## Sobre o projeto

O Nutri-bit é um projeto acadêmico que busca facilitar o planejamento alimentar e o acompanhamento nutricional, proporcionando uma interface intuitiva, responsiva e integrada entre as plataformas mobile e web.
