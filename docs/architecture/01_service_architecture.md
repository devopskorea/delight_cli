# 서비스 아키텍처

## 1. 개요

`delight_cli`는 Dooray!(두레이) SaaS의 REST API를 호출하는 단일 바이너리 CLI 도구이다.
자체 백엔드 서버, 데이터베이스, 프론트엔드를 보유하지 않는다. 모든 상태는 Dooray 측에 존재하며, 로컬에는 다음만 보관한다.

- 사용자 설정(YAML)
- 다운로드 캐시(SDBM 키-값 DB 2개)
- 다운로드/업로드 대상 파일

## 2. 컴포넌트 구성

```
┌─────────────────────────────────────────────────────────┐
│                     사용자 터미널                         │
└────────────────────────┬────────────────────────────────┘
                         │ delight <command> ...
                         ▼
┌─────────────────────────────────────────────────────────┐
│  bin/delight  (CLI 엔트리포인트, 1528 LOC)               │
│  ─ 명령어 디스패치(if/elsif chain)                        │
│  ─ 옵션 파싱(Getopt::Long)                                │
│  ─ UTF-8 정규화                                          │
└──────┬──────────────────┬───────────────────────┬────────┘
       │ load             │ call                  │ read/write
       ▼                  ▼                       ▼
┌────────────────┐ ┌───────────────────┐ ┌──────────────────┐
│ Delight::Config│ │ Delight::Dooray   │ │ 로컬 파일시스템    │
│ (YAML 설정)    │ │ (HTTP 클라이언트) │ │ ─ download_dir    │
└──────┬─────────┘ └─────────┬─────────┘ │ ─ upload_dir      │
       │                     │           │ ─ *.sdbm 캐시     │
       ▼                     ▼           └──────────────────┘
┌────────────────┐ ┌───────────────────┐
│ config.yml /   │ │   Dooray REST API │
│ ~/.delight.yml │ │ api.dooray.com    │
└────────────────┘ │ file-api.dooray.com│
                   └───────────────────┘
```

## 3. 모듈 책임

| 파일 | 역할 | LOC |
|---|---|---|
| `bin/delight` | 명령어 라우팅, 옵션 파싱, 출력 포맷팅, 파일 I/O | 1528 |
| `lib/Delight/Config.pm` | YAML 설정 로드/저장 (`config.yml` → `~/.delight.yml`) | 54 |
| `lib/Delight/Dooray.pm` | Dooray API HTTP 클라이언트, 더블 UTF-8 디코딩 보정 | 384 |
| `lib/Delight/Auth.pm` | **(미사용)** Google OAuth2 스캐폴딩 — `bin/delight`에서 참조 안 함 | 81 |
| `lib/Delight/Drive.pm` | **(미사용)** Google Drive v3 클라이언트 — `bin/delight`에서 참조 안 함 | 40 |

## 4. 명령어 카테고리

| 카테고리 | 진입 토큰 | 별칭 |
|---|---|---|
| 계정 | `whoami` | — |
| 프로젝트 | `project list`, `project settings` | — |
| 태스크 | `task ...` | `post ...` |
| 위키 페이지 | `page ...` | `wiki ...` |
| 캘린더 | `calendar +agenda`, `calendar events ...`, `calendar +insert`, `calendar freebusy query` | — |
| 드라이브 | `drive files ...`, `drive +upload` | — |
| 일괄 다운로드 | `download tasks|wiki|drive` | — |
| 일괄 업로드 | `upload drive` | — |
| 설정 | `config <key> <value>` | — |

## 5. 디스패치 흐름 (단일 진입)

```
ARGV → shift command
  ├─ whoami       → Dooray.whoami
  ├─ project      → list_projects | list_workflows/milestones/tags/members
  ├─ calendar     → list_events | create_event | get/update/delete_event | invite | freebusy
  ├─ drive        → list_files | upload_file
  ├─ page|wiki    → create/update/upload/download/delete/undelete wiki page
  ├─ task|post    → create/list/count/tag/duedate/phase/status/assign/delete/undelete/download/upload
  ├─ download     → tasks | wiki | drive  (SDBM 캐시 + 랜덤 2~10s delay)
  ├─ upload       → drive (mtime+size 기반 SDBM 캐시)
  └─ config       → set key/value, save YAML
```

## 6. 인증 모델

- 유일한 자격증명: Dooray 개인 인증 토큰 (config의 `token` 키)
- 모든 API 요청에 `Authorization: dooray-api <token>` 헤더 부착 (`Delight::Dooray::_auth_header`)
- OAuth2/리프레시 없음. 토큰 만료 시 사용자가 직접 재발급 후 `delight config token <new>` 호출

## 7. 더블 UTF-8 디코딩 처리

Dooray API는 한국어 응답에서 UTF-8 바이트열을 한 번 더 UTF-8로 인코딩해 보낸다.
`Delight::Dooray::_fix_double_utf8`가 응답 트리를 재귀 순회하며 두 번째 UTF-8 레이어를 제거한다.
판별 조건: 문자열에 `[\xC2-\xF4][\x80-\xBF]` 패턴(=UTF-8 시작 바이트 + continuation 바이트)이 있을 때.
