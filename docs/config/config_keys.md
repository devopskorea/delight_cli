# 설정 (환경변수 / config.yml)

## 1. 환경변수: **사용 안 함**

`delight_cli`는 OS 환경변수를 읽지 않는다.
모든 설정은 YAML 파일(`config.yml` 또는 `~/.delight.yml`)에서 로드된다.

코드 상 환경변수 참조 검색 결과: `bin/delight`, `lib/Delight/*.pm`에서 `$ENV{...}` 사용 0건.

> 향후 토큰을 환경변수로 받고자 한다면 `Delight::Config::load`에 `$ENV{DELIGHT_TOKEN}` 폴백을 추가하는 것을 권장한다.

## 2. 설정 파일 우선순위

`Delight::Config::new`(`lib/Delight/Config.pm:11`):

1. 호출 시 `config_path` 인자가 주어지면 그 경로
2. 그렇지 않으면 **현재 작업 디렉토리의 `config.yml`** (있을 때)
3. 둘 다 없으면 `$HOME/.delight.yml`
4. 그것도 없으면 빈 기본값 (`domain=https://api.dooray.com`, `token=''`)

## 3. 설정 키 사전

| 키 | 타입 | 기본값 | 사용 위치 | 설명 |
|---|---|---|---|---|
| `token` | string | (필수) | `Delight::Dooray::_auth_header` | Dooray 개인 인증 토큰. 형식: `<keyId>:<secret>` |
| `domain` | URL string | `https://api.dooray.com` | `Delight::Dooray::request`, `_file_api_url` | API 베이스. `api.` → `file-api.` 자동 치환으로 파일 API 도메인 도출 |
| `default_project_id` | string | (선택) | 다수 명령 (`task list/count`, `download tasks`, `drive` 결정 체인 등) | `--project-id` 미지정 시 사용 |
| `default_wiki_id` | string | (선택) | `page` 명령들, `download wiki` | `--wiki-id` 미지정 시 사용 |
| `default_drive_id` | string | (선택) | `drive` 명령들, `upload drive`, `download drive` | `--drive-id` 미지정 시 사용 |
| `default_calendar_id` | string | `primary` (코드상 `'primary'` 폴백) | `calendar` 명령들 | `primary` 또는 미지정이면 `get_default_calendar_id` API로 동적 결정 |
| `download_dir` | path | `$HOME/delight` | `bin/delight::base_dir` | 모든 다운로드 산출물의 루트 |
| `upload_dir` | path | `$HOME/delight_upload` | `delight upload drive` | 동기화 대상 소스 디렉토리 |

## 4. `config_example.yml`과 실제 사용 키 비교

`config_example.yml` 현재 내용:

```yaml
domain: https://api.dooray.com
token: xxxxxxxxxxxx:yyyyyyyyyyyyyyyyyyyyyy
default_project_id: "1234567890123456789"
default_wiki_id: "1234567890123456789"
default_drive_id: "1234567890123456789"
default_calendar_id: "1234567890123456789"
```

코드는 사용하지만 example에 **누락된 키**: `download_dir`, `upload_dir`.
→ 사용자가 폴백 위치(`$HOME/delight`, `$HOME/delight_upload`)를 모르고 권한 문제 또는 경로 혼동 가능.
**권장**: `config_example.yml`에 두 키를 주석으로라도 추가.

## 5. 설정 변경 방법

```bash
# 단일 키
delight config token <new-token>

# 명령은 YAML 라운드트립으로 저장 (Delight::Config::set + save)
# - CWD에 config.yml이 있으면 그 파일을 갱신
# - 없으면 ~/.delight.yml에 저장
```

## 6. 보안

- `.gitignore`에 `config.yml` 등재됨 — 토큰 누설 방지.
- 실수로 커밋 방지: `git diff --cached config.yml` 검사 권장.
- 토큰 회전 시 `delight config token <new>` 후 즉시 `delight whoami`로 검증.

## 7. 별도로 존재하지만 미사용

`lib/Delight/Auth.pm`은 `~/.delight_cli.ini`(INI 형식)에서 OAuth2 client_id/secret을 기대하지만, **`bin/delight`에서 import되지 않으므로 실제로 사용되지 않는다**. 정리 대상.
