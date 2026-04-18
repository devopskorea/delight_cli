# 2026-04-18 — 프로젝트 초기 분석

## 요청

`@../project_analyzing_method.md` 기반으로 현재 프로젝트(`delight_cli`) 분석 — 옵션 B(원문 그대로 강행, 부적합 항목은 N/A로 명시).

원본 method 문서 항목:
1. 레포 + 서브모듈 분석
2. 서비스/인프라/DB/API 분석 문서
3. DB-API-서비스-기능 관계 문서
4. 유저 시나리오
5. 전체 URL 테스트(Playwright)
6. Backend/Frontend/Admin 테스트 커버리지
7. 개발/미개발 기능 정리
8. docs 폴더에 md 저장
9. 코드 변경시 docs 동기화 가이드
10. 환경변수 정리
11. 브랜치 전략
12. Cloudflare Worker 구성
98. 작업 히스토리 저장
99. README 링크 갱신

## 처리 결과

### 적용 가능 (그대로 수행)

| # | 산출물 |
|---|---|
| 1 | `docs/architecture/01_service_architecture.md` (서브모듈 없음 명시) |
| 2 | `docs/architecture/01~04_*.md` (서비스/인프라/DB/API) |
| 3 | `docs/relations/command_api_file_matrix.md` |
| 4 | `docs/scenarios/user_scenarios.md` (S-01 ~ S-13) |
| 7 | `docs/features/feature_status.md` (구현 7개 영역, 결함 16개) |
| 8 | 모든 산출물을 `docs/` 하위에 분야별 폴더로 저장 |
| 9 | `docs/ops/docs_maintenance.md` (코드↔문서 매핑) — *후속 결정으로 `.gitignore` 처리* |
| 11 | `docs/ops/branch_strategy.md` (main/dev/feature/bug) — *후속 결정으로 `.gitignore` 처리* |
| 99 | `README.md`에 docs 인덱스 섹션 추가 |

> **사후 결정 (2026-04-18):** `.gitignore`에 `docs/ops/`, `docs/testing/`이 추가되어 git 추적에서 제외됨. 사용자 옵션 B 선택에 따라 `README.md`/`docs/README.md`의 인덱스에서 해당 링크 제거. 파일 자체는 로컬 디스크에 보존되어 작업자 개인 참고용으로 사용.

### 부분 적용 / 대체

| # | 처리 |
|---|---|
| 5 | Playwright는 CLI에 부적합 → 31건의 매뉴얼 테스트 케이스를 `docs/testing/test_plan.md`에 정리(*`.gitignore` 처리*). 알려진 실패 2건(F-01, F-02) 기록. |
| 6 | Backend/Frontend/Admin 부재 → CLI 명령별 자동 테스트 커버리지 매트릭스로 대체 (`docs/testing/cli_coverage.md`, *`.gitignore` 처리*). 현재 자동 테스트 0%. |
| 10 | 환경변수 미사용 → `docs/config/config_keys.md`에서 `config.yml` 키 사전 + 환경변수 폴백 권장 정리. |

### N/A 명시

| # | 처리 |
|---|---|
| 12 | Cloudflare Workers / Supabase 미사용 → `docs/ops/cloudflare_workers.md`에 N/A 사유와 CLI 환경 구분 대체안 기록 (*`.gitignore` 처리*). |
| 3(부분) | 자체 DB 없음 → `docs/architecture/03_database.md`는 로컬 SDBM 캐시 + Dooray 외부 리소스 매핑으로 작성. |

### 발견된 결함 (Code Smells / Bugs)

| ID | 위치 | 설명 |
|---|---|---|
| G-01 | `bin/delight:50, 1221` | `Delight::Dooray::get_wiki_id_by_project_id` 미구현 |
| G-02 | `samples/check_by_project_id.pl:64` | `Delight::Dooray::list_wiki_pages` 미구현 |
| G-03 | `lib/Delight/Auth.pm` 전체 | 미사용 데드코드 (Google OAuth2) |
| G-04 | `lib/Delight/Drive.pm` 전체 | 미사용 데드코드 (Google Drive v3) |
| G-13 | `bin/delight:813` | 사용 안 함 변수 `$tag_prefix` |
| G-05 | `config_example.yml` | `download_dir`/`upload_dir` 키 누락 |

전체 16건은 `docs/features/feature_status.md` 2절 참고.

## 다음 단계 권장

1. P0 결함(G-01, G-03/G-04) 의사결정 — 미사용 모듈 삭제 또는 의존성 정상화
2. `dev` 브랜치 생성 및 보호 규칙 설정
3. 최소 단위 테스트 도입 (`t/_fix_double_utf8.t`, `t/_format_task.t`)
4. README `docs` 인덱스 검증

## 참여

- Requester: devworld.ltd@gmail.com
- Mode: 옵션 B (원문 강행 + N/A 명시)
- 작업일: 2026-04-18
