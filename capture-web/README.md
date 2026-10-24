# SoC Capture Web — Vivado/Vitis 실습 화면 캡처

GitHub Pages에서 바로 실행하는 **설치 없는 웹앱**입니다. 기존 PyQt5/X11 프로그램과 별개의 구현입니다.

- 브라우저가 제공하는 화면 공유로 Vivado/Vitis 창 또는 전체 화면을 선택
- **현재 화면 PNG 저장**: 수동 1회 촬영
- **5초 후 촬영**: 전체 화면 공유 시 버튼을 누르고 Vivado/Vitis로 돌아갈 시간을 확보
- **영역 선택**: 미리보기 위에서 드래그한 부분을 원본 해상도로 저장
- **자동 캡처**: 공유 화면의 이미지 변화를 감지하고 약 1.2초 안정된 뒤 촬영 (최소 간격 4/6/10초)
- `ch01/step01/raw/` 같은 장·STEP별 하위 폴더 자동 생성
- `captures.csv`에 시각, 장, 단계, 저장 경로, SHA-256, `UNREVIEWED` 기록
- 모든 이미지와 CSV는 **사용자가 지정한 로컬 폴더**에만 저장. GitHub나 다른 서버로 전송하지 않음

## 권장 환경

- Ubuntu 24.04, 최신 Chrome 또는 Chromium / Edge 데스크톱 브라우저
- HTTPS로 서비스되는 GitHub Pages 또는 로컬 `http://localhost:8000`
- 로컬 디렉터리 선택 API(`showDirectoryPicker`)와 화면 공유 API(`getDisplayMedia`) 지원 필수
- 화면 공유 재접속 시 브라우저에서 매번 허용해야 함

## 사용법

1. Ubuntu 파일 관리자에서 `~/soc/evidence` 폴더를 직접 생성합니다(없다면).
2. 웹앱에서 **저장 폴더 선택** → 해당 폴더를 선택하고 접근 권한을 허용합니다.
3. **챕터**와 **STEP** 번호를 정합니다.
4. **화면 공유 시작** → Vivado/Vitis 창 또는 화면 전체를 선택합니다.
   - 메뉴/모달창이 별도 창으로 뜰 경우, **전체 화면**을 선택하는 것이 더 안정적입니다.
   - 브라우저 자체 화면이 캡처되지 않도록 Vivado/Vitis를 전면에 배치합니다.
5. **현재 화면 PNG 저장** 또는 **자동 캡처 시작**을 선택합니다.
   - 전체 화면 공유 중에는 버튼 클릭 순간 브라우저가 찍힐 수 있으므로 **5초 후 촬영**을 선택하고 Vivado/Vitis로 돌아갑니다.
6. 다음 실습에서 **다음 STEP**을 누릅니다.
7. 파일 관리자에서 `~/soc/evidence` 아래 PNG와 `captures.csv`를 확인합니다.

선택한 최상위 폴더가 `evidence`라면 폴더 구조는 아래와 같습니다.

```text
evidence/
├── captures.csv
├── ch01/
│   ├── step01/
│   │   └── raw/
│   │       ├── ch01_step01_20261025_..._manual_XXXXXXXX.png
│   │       └── ch01_step01_20261025_..._auto_change_XXXXXXXX.png
│   └── step02/raw/
└── ch02/step01/raw/
```

**중요:** 위의 날짜 파일명은 설명용 예시이며 실제 실행 결과가 아닙니다. 각 파일명은 캡처 순간의 로컬 시각과 고유 접미사를 사용합니다.

## 브라우저 환경에서 불가능하거나 달라진 기능

| 이전 Ubuntu GUI 프로그램 | 웹 버전 |
|---|---|
| X11 전역 마우스 클릭 자동 감지 | **불가**, 대신 화면 내용 변화 감지 |
| OS 수준 Vivado 메인창 및 관련 모달창 추적 | **불가**, 브라우저 화면 공유 대상으로 전체 화면 또는 창 선택 |
| 전역 Ctrl+Shift+F8/F9/F10/F12 | **불가**, 웹앱의 버튼으로 조작 |
| `scrot` 화면 촬영 | 브라우저 `getDisplayMedia` + `canvas` |
| 로컬 파일 저장 | 브라우저 File System Access API로 동일 기능 |

자동 캡처는 감시 화면의 변화를 일정 간격으로 비교합니다. 변화가 매우 작거나 짧게 지나가면 기록하지 않을 수 있습니다. 탭이 백그라운드에서 장시간 제한되거나 시스템이 절전 상태가 되어도 촬영 간격이 달라질 수 있습니다. 중요한 성공/실패 상태는 수동 촬영으로도 남기는 것을 권장합니다.

## 데이터 및 안전

- 화면 데이터는 메모리에서 PNG로 변환되며 **선택한 로컬 폴더 이외의 목적지로 전송하지 않습니다.**
- GitHub Pages는 정적 파일(HTML/CSS/JS)을 제공하는 용도로만 사용합니다.
- 화면 공유 권한은 매 세션 사용자가 선택해야 하며, 폴더 권한도 브라우저 정책에 따라 재확인이 필요합니다.
- 브라우저는 사용자 지정 로컬 절대경로를 자유롭게 열 수 없습니다. 반드시 폴더 선택창을 사용합니다.
- CSV 열 구성은 기존 `soc_capture_gui`의 `captures.csv`와 호환되며, OS 창 ID/전역 클릭 좌표는 웹에서 읽을 수 없어 빈 값으로 남깁니다.
- 저장된 모든 항목은 처음에 `UNREVIEWED` 상태입니다. 정상, 중간, 오류 등 판정은 별도로 수행합니다.
- 화면 공유와 저장 기능은 스스로 활성화해야 하며, 이 웹앱은 인터넷으로 이미지를 업로드하거나 Vivado/Vitis 프로젝트를 수정하지 않습니다.

## GitHub Pages 게시

기존 `Yuul-Jung/soc` 저장소의 최상위에 **`capture-web/`** 폴더로 업로드하는 경우:

```text
soc/
├── ... (기존 자료 그대로 유지)
└── capture-web/
    ├── index.html
    ├── style.css
    ├── app.js
    ├── README.md
    └── .nojekyll
```

Pages가 `main` 브랜치 `/ (root)`를 게시하도록 설정되어 있다면 주소는 다음과 같습니다.

`https://yuul-jung.github.io/soc/capture-web/`

프로젝트를 따로 게시하려면 `soc-capture-web` 저장소의 루트로 같은 파일을 올리고 `Settings → Pages → Deploy from a branch → main / (root)`를 설정할 수 있습니다.

## 로컬 테스트

```bash
# 이 폴더에서 8000번 포트에 정적 웹 서버를 실행합니다.
python3 -m http.server 8000

# 같은 PC의 Chromium에서 열어 확인합니다.
# http://localhost:8000/
```

`file://`로 HTML을 직접 열면 보안 컨텍스트/권한 정책에 따라 화면 공유와 폴더 선택이 차단될 수 있습니다.

## 기존 Python 프로그램과의 관계

원본 `soc_capture_gui.zip`의 주요 기능·폴더 구조·CSV 열 정의만 참고했습니다. Python, PyQt5, X11, 설치 스크립트는 사용하지 않습니다. 기존 ZIP 또는 실행 프로그램 삭제 여부와 상관없이 동작합니다.