# Data Contract

Android must remain compatible with iOS and Web backups.

## Backup JSON

Top-level fields:

```json
{
  "schema_version": 1,
  "assets": {},
  "expenses": [],
  "incomes": [],
  "passive_sources": [],
  "first_record_date": "2026-01-01"
}
```

## Assets

```json
{
  "total": 500,
  "locked_assets": 300,
  "cash": 200,
  "updated_at": "2026-05-25T08:55:55.159Z"
}
```

Rules:

- `total` is retained for old files and external readers.
- `locked_assets + cash` is the real current net worth.
- If old files only have `total`, Android imports it into `cash` and sets `locked_assets = 0`.

## Expense

```json
{
  "id": "uuid",
  "amount": 25.5,
  "category": "午餐",
  "date": "2026-01-15",
  "note": "",
  "created_at": "2026-01-15T10:00:00Z"
}
```

Canonical categories:

```text
早餐 / 午餐 / 晚餐 / 购物 / 交通 / 娱乐 / 成长投资 / 医疗 / 其他
```

Unknown imported categories must be normalized at the import boundary.

## Income

```json
{
  "id": "uuid",
  "amount": 1600,
  "source": "工资",
  "date": "2026-01-15",
  "note": "",
  "is_passive": false,
  "created_at": "2026-01-15T10:00:00Z"
}
```

`is_passive` is kept for backward compatibility. Current product semantics use `passive_sources` as the real passive-income engine.

## Passive Source

```json
{
  "name": "股息",
  "monthly_amount": 300
}
```

Daily passive income is `sum(monthly_amount / 30)`.

## Date Rules

- User-facing transaction dates use local natural days: `YYYY-MM-DD`.
- Created/updated timestamps use ISO 8601.
- Freedom-day history must compare transaction dates by local natural day, not raw timestamp.
