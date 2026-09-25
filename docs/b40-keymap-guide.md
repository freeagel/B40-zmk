# B40 ZMK 키맵 사용 가이드

이 문서는 현재 `b40.keymap`과 빌드 설정을 기준으로 작성되었습니다.

## 레이어 진입

- **Base**: 기본 레이어입니다.
- **Number**: Base 하단의 `Number` 키를 누르고 있는 동안 활성화됩니다.
- **Number Shift**: Base 하단의 `NumShift` 키를 누르고 있는 동안 활성화됩니다.
- **Nav**: Base 하단의 `Nav` 키를 누르고 있는 동안 활성화됩니다.
- **Management**: Base에서 `Q + P`를 동시에 누르고 있는 동안 활성화됩니다. 콤보 제한 시간은 100ms입니다.
- 이미지의 `·` 표시는 투명 키이며, 아래쪽 Base 레이어의 같은 위치 키가 동작합니다.

## Nav 레이어

- `Nav + E/D`: 위/아래 방향키
- `Nav + S/F`: 왼쪽/오른쪽 방향키
- `Nav + .`: 위, `Nav + -`: 왼쪽, `Nav + ;`: 아래, `Nav + Enter`: 오른쪽 방향키입니다.
- `Nav + Number`: 스크롤 위
- `Nav + Space`: 스크롤 아래
- `Nav + LShift`: GUI(Windows/Command) 키
- `Nav + Q`: Escape
- `Nav + W/R`: Home/End
- `Nav + A`: Tab
- `Nav + Backspace`: Delete
- `Nav + U/I/O`: 마우스 왼쪽 클릭/위 이동/오른쪽 클릭
- `Nav + J/K/L`: 마우스 왼쪽/아래/오른쪽 이동
- `Nav + P`: Alt+Tab
- `Nav + H`: Android 시스템 단축키 `GUI + H`로 홈 화면 이동
- `Nav + B/N`: Android 키보드 HID 방식의 뒤로/앞으로
- 스크롤은 가속 없이 고정 속도 **30**으로 동작합니다.

## 절전과 깨우기

- Base에서 `Q + P`를 계속 눌러 Management 레이어를 활성화한 뒤 `Space`를 2초보다 길게 누르고 놓으면 절전 상태로 들어갑니다.
- 기존 `H + NumShift + Nav` 절전 콤보는 Android Home(`Nav + H`)과의 충돌을 막기 위해 제거했습니다.
- 절전 상태에서는 **H 키**로 깨웁니다.

## Bluetooth 프로필과 페어링

Management 레이어의 맨 윗줄과 맨 아랫줄을 사용합니다. 진입 키인 Q/P와 바로 옆 W/O는 오입력 방지를 위해 비워 두었습니다.

- Base에서 `Q + P`를 계속 누른 상태로 아래 관리 키를 추가로 누릅니다.
- `E/R/T/Y/U`: Bluetooth 프로필 `P0/P1/P2/P3/P4` 선택
- `I`: ZMK Studio 잠금 해제
- Base의 `Number` 위치: 현재 선택한 프로필의 페어링 정보 삭제(`BT Clear`)
- Base의 `Nav` 위치: 모든 Bluetooth 프로필 삭제 후 P0 선택(`BT Clear All`)
- Base의 `-` 위치: 키보드 재부팅(`Reset`). Bluetooth 프로필은 보존됩니다.
- 새 기기와 연결할 때는 비어 있는 프로필을 선택한 뒤 휴대폰이나 PC의 Bluetooth 목록에서 B40을 등록합니다.
- 이미 등록된 기기에서 재페어링할 때는 호스트의 기존 B40 등록도 삭제하고, 키보드의 해당 프로필도 `BT Clear`한 뒤 다시 등록합니다.
- 연결 표시는 되지만 입력되지 않으면 해당 기기의 프로필을 다시 선택하고, 계속 문제가 있으면 `Reset`을 누릅니다.
- 어느 프로필이 꼬였는지 모를 때만 `BT Clear All`을 사용하고 모든 기기를 다시 페어링합니다.
- Android에서도 같은 방식으로 프로필을 선택하고 페어링합니다.

Management의 나머지 행에는 다음 보조 키가 있습니다.

- 두 번째 행: `F1`~`F10`
- 세 번째 행: `F11`, `F12`, `Page Up`, `Page Down`, `Home`, `End`, 음량 내림/올림, 음소거, 재생/일시정지
- 네 번째 행: 이전/다음 트랙, 화면 밝기 내림/올림, `BT Clear`, `Sleep`, `BT Clear All`, `Reset`, `Undo`, `Redo`
- `Caps Lock`, `Insert`, `Print Screen`은 의도적으로 제외했습니다.

## ZMK Studio

- Management 레이어의 `I` 위치가 `Studio Unlock`입니다.
- Base에서 `Q + P`를 누른 상태로 `I`를 눌러 Studio 잠금을 해제합니다.
- Studio에서 저장한 동적 키맵은 키보드 내부 저장소에 남으며 펌웨어의 기본 키맵보다 우선합니다.
- 새 펌웨어의 기본 키 배치를 적용하려면 Studio에서 **Restore Stock Settings**를 실행합니다.
- Restore Stock Settings는 Studio에서 직접 저장한 키 배치를 현재 펌웨어 기본값으로 덮어씁니다.
- 콤보, 절전 웨이크 GPIO, 스크롤 속도 같은 펌웨어 설정은 Studio에서 직접 편집할 수 없습니다.

## 펌웨어 파일

- 일반 사용: `local-firmware/b40-normal.uf2`
- Studio 잠금 문제 복구: `local-firmware/b40-recovery.uf2`
- 전체 설정 초기화가 꼭 필요할 때만: `local-firmware/b40-settings-reset.uf2`

부트로더 모드에서 나타나는 USB 드라이브에 필요한 UF2 파일을 복사합니다. 일반적인 키맵 업데이트에는 Bluetooth 재페어링이 필요하지 않습니다.
