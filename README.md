# RFL Mobile 0.1 — projeto inicial Android

Este pacote é um **protótipo-fonte Flutter**, não um APK pronto. O ambiente de criação não possui Flutter/Android SDK instalado, então não foi possível compilar nem testar em dispositivo.

## Requisitos
- Flutter SDK estável
- Android Studio + Android SDK
- Android físico ou emulador

## Criar o projeto Android completo e executar
O ZIP contém o código-fonte Flutter e os arquivos de configuração do app, mas não inclui os arquivos de plataforma gerados pelo Flutter SDK. Em uma máquina com Flutter instalado:
```bash
flutter create --platforms=android rfl_mobile
```
Depois copie `lib/main.dart` e `pubspec.yaml` deste pacote para a pasta `rfl_mobile` (substituindo os existentes) e execute:
```bash
cd rfl_mobile
flutter pub get
flutter run
```

## Gerar APK de teste
```bash
flutter build apk --debug
```

## O que esta primeira base contém
- Interface escura profissional adaptável: layout compacto para celular e painel lateral para telas maiores.
- Ferramentas iniciais de mover, pincel e borracha (o pincel é um protótipo de traço livre).
- Área de trabalho com régua ilustrativa e guias centrais.
- Painel de camadas básico.
- Importação de imagem selecionada (nesta versão ainda não compõe a imagem visualmente no canvas).
- Salvamento de estrutura de projeto JSON e importação básica de camadas.
- Eventos de ponteiro Flutter com leitura de pressão como ponto inicial para canetas compatíveis.

## Limitações explícitas da 0.1
- Não é ainda um editor completo nem compatível integralmente com `.rfl` do Windows.
- A importação da imagem ainda não a renderiza no canvas.
- Pressão da caneta é recebida pelo evento, mas ainda não controla espessura; inclinação não foi implementada.
- RFL Sync ainda não existe; nesta fase há importação/exportação local básica. Sincronização por Wi-Fi/internet virá depois.
- Não há RFL AI conectada.
- Nenhuma alteração é feita no código Windows. O RFL Studio para Windows continua sendo desenvolvido separadamente.

## Direção técnica
Flutter para a aplicação Android; Python/PySide6 permanece no Windows. O intercâmbio será construído por um formato de projeto comum versionado, sem tentar executar PySide6 no Android.


## Gerar o APK pela nuvem (sem compilar no seu PC)
1. Crie uma conta no GitHub, se ainda não tiver.
2. Crie um repositório novo e envie **todo o conteúdo** desta pasta para ele.
3. Abra a aba **Actions** do repositório.
4. Selecione **Build RFL Mobile APK** e toque em **Run workflow** (ou aguarde o build após enviar para a branch `main`).
5. Quando terminar, abra a execução concluída e baixe o artefato **RFL-Mobile-APK**.
6. Extraia o ZIP baixado. Dentro dele estará `app-release.apk`. Transfira esse APK para o Android e instale.

O workflow compila o código na infraestrutura do GitHub Actions. O APK ainda será um protótipo 0.1; não representa o editor Windows completo e ainda não possui sincronização funcional com o RFL Studio.
