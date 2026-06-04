# Quality Automation & Testing Engine

## Testing Architecture (Engine Pattern)
- **Philosophy:** Logic != Data.
- **One Logic = One Test Function.** Infinite scenarios via parametrization.
- **NEVER** write individual test functions per scenario.

### The Engine Pattern Code
```python
# 1. Config
TARGET_FUNCS = [("polars", read_polars), ("orjson", read_orjson)]
TEST_SCENARIOS = {
    "empty": {"data": [], "validators": {"polars": lambda r: r.height == 0}},
    "valid": {"data": [...], "validators": {"polars": lambda r: r.height > 0}},
}

# 2. Engine (The ONLY test function)
@pytest.mark.parametrize("func_id, func_impl", TARGET_FUNCS)
@pytest.mark.parametrize("scenario", TEST_SCENARIOS.keys())
def test_engine(json_factory, func_id, func_impl, scenario):
    # Setup -> Execute -> Validate (via lambda)
```

## Makefile Standard
```makefile
make install   # uv sync
make format    # ruff format
make lint      # ruff check --fix
make check     # Run all quality checks
```
