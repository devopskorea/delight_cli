# 인프라 아키텍처

## 1. 배포 모델

`delight_cli`는 **사용자 단말기에서 실행되는 클라이언트 사이드 도구**이다.
서버, 컨테이너, 클라우드 인프라가 없다. CI/CD 파이프라인도 정의되어 있지 않다.

## 2. 배포 산출물

| 산출물 | 경로 | 용도 | 크기 |
|---|---|---|---|
| Linux x64 바이너리 | `delight-linux-x64` | Perl 미설치 환경에서 즉시 실행 | ~9.4 MB |
| Windows 바이너리 | `delight.exe` | Windows에서 즉시 실행 | ~11.2 MB |
| Perl 스크립트 | `bin/delight` | Perl 환경에서 직접 실행 | 1528 LOC |

> 두 바이너리는 PAR/PerlApp 류 도구로 빌드된 것으로 보이나, 빌드 스크립트는 레포에 포함되어 있지 않다.

## 3. 런타임 의존성 (Perl 환경)

`cpanfile`:

```
LWP::UserAgent
JSON::XS
YAML::XS
Getopt::Long
File::HomeDir
File::Spec
URI
HTTP::Request::Common
```

`Makefile.PL`의 `PREREQ_PM`에는 추가로 `LWP::MediaTypes`, `URI::Escape`가 명시되어 있다.

`bin/delight`에서 직접 사용되는 코어/추가 모듈:

```
Encode, POSIX, Time::Piece, Fcntl, SDBM_File, File::Path
```

`lib/Delight/Auth.pm`(미사용)에는 `LWP::Authen::OAuth2`, `Config::Tiny`, `JSON::MaybeXS`가 필요하나 `cpanfile`에 누락. → 정리 필요(미사용 코드 제거 또는 의존성 동기화).

## 4. 외부 종속성

| 호스트 | 용도 | 인증 |
|---|---|---|
| `https://api.dooray.com` | 메인 API 도메인 (기본값) | `Authorization: dooray-api <token>` |
| `https://file-api.dooray.com` | 파일 업로드 도메인 (`api.` → `file-api.`로 치환) | 동일 |

`config.yml`의 `domain`을 변경하면 두 호스트 모두 변경된다(`Delight::Dooray::_file_api_url`).

## 5. 로컬 스토리지 레이아웃

```
$download_dir/                       # 기본: $HOME/delight
├── project_<projectId>/
│   ├── settings.md                  # delight project settings 결과
│   ├── <postId>.md                  # delight task download
│   ├── <postId>-<slug>.md           # delight download tasks
│   └── <postId>_attachments/        # --with-attachments
├── wiki_<wikiId>/
│   ├── <pageId>.md                  # delight page download / download wiki
│   └── <pageId>_attachments/
├── drive/
│   └── <sanitizedName>_<fileId>     # delight download drive
└── WIKI_MAP_<wikiId>.md             # 위키 계층 맵

$upload_dir/                         # 기본: $HOME/delight_upload
└── (사용자가 넣어두는 파일들 — `delight upload drive` 대상)

# 작업 디렉토리(현재 폴더)에 생성됨
.delight_download_cache.sdbm.dir/.pag
.delight_upload_cache.sdbm.dir/.pag
```

## 6. 캐시 정책

- **다운로드 캐시**: SDBM 키 = `task_<id>` / `wiki_<id>` / `drive_<id>`. 값이 truthy면 스킵. `--reset-cache`로 초기화.
- **업로드 캐시**: SDBM 키 = `<filename>_<size>_<mtime>`. mtime 또는 size 변화 시 새 키가 되어 재업로드 트리거. 동일 키는 스킵.
- 캐시 파일은 **CWD에 생성**되므로 실행 디렉토리에 따라 분리됨.

## 7. 서버 부하 보호

`download` / `upload` 명령은 매 파일 처리 후 `int(rand(9)) + 2` 초(2~10초) 무작위 대기. `--delay 0`으로 비활성화.

## 8. CI/CD

레포에 `.github/workflows/`, `Dockerfile`, 배포 스크립트 없음. 바이너리는 수동 빌드/커밋되는 것으로 보임(`delight-linux-x64`, `delight.exe`가 git에 포함됨).
