---
jupyter:
  jupytext:
    formats: ipynb,md
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.2'
      jupytext_version: 1.8.0
  kernelspec:
    display_name: Python 3
    language: python
    name: python3
---

```python tags=["remove_cell"]
import pathlib
import tempfile
import typing
import textwrap

import pandas
import pytest
import ipytest
import _pytest

ipytest.autoconfig()

def check_input_file(input_file: pathlib.Path) -> None:
    if not input_file.is_file():
        raise FileNotFoundError("")

def run_cli(input_file: pathlib.Path) -> None:
    """Helper to simulate running a cli tool."""
    try:
        check_input_file(input_file)
    except FileNotFoundError:
        return 1
    return 0

def long_running_computation() -> typing.Tuple[pathlib.Path, pathlib.Path]:
    """Helper method to generate some example pandas data"""

    raw_collected_data = pandas.DataFrame(
        {
            "sample_id": [1, 1, 2, 2, 1, 1, 2, 2],
            "measurement": [0.1, 0.09, 2, 2.3, 5, 4.8, 7.2, 8.3],
            "test_variable": ["A", "A", "A", "A", "B", "B", "B", "B"],
        }
    )

    # Here's the raw output
    raw_data_file = tmp_path / "raw_data.csv"
    raw_data_file.write_text(raw_collected_data.to_csv())

    # Here's some computation on the raw output
    averages_data_file = tmp_path / "sample_averages.csv"
    averages_data_file.write_text(
        raw_collected_data.groupby(["sample_id"]).agg("mean").to_csv()
    )




def fetch_file_from_s3() -> pathlib.Path:
    """Simulate fetching a very large file from s3 that takes a while to download."""
    print("Fetching a large file from S3.")
    _, loc = tempfile.mkstemp()
    return pathlib.Path(loc)
```


I use pytest in most python projects, and I've had a feeling that I haven't been
been using most of the features it provides, since I tend to only use
`@pytest.mark` from the API. I spent some time reading through the pytest
documentation and playing with some examples in the source [pytest jupyter
notebook][] to get more familiarity with what's possible. After a few hours of
playing around with pytest, realised there was a lot of functionality I was
missing. Read below for some of the examples. Most of this is just a
reconstitution of whats in the [pytest documentation][] for my own
self-learning. Additionally there's useful videos, and plugins on the [awesome
pytest][] GitHub repository.

[pytest jupyter notebook]:
  https://github.com/michaelbarton/jupyer-pytest-api-examples
[pytest documentation]: https://docs.pytest.org/en/stable/example/index.html
[awesome pytest]: https://github.com/augustogoulart/awesome-pytest

## Pytest Fixtures

Fixtures are a large part of the pytest API, and the part I was least familiar
with. Fixtures are used in pytest tests by including them as parameters to test
functions. The pytest API comes with a few builtin fixtures: useful ones for
temporary files are `[tmp_path][]` and `[tmp_path_factory][]` shown below.

[tmp_path_factory]:
  https://docs.pytest.org/en/stable/tmpdir.html#tmp-path-factory-example

```python tags=["remove_output"]
%%run_pytest[clean] -qq -s --cache-clear

def test_with_tmp_path(tmp_path: pathlib.Path):
    """The `tmp_path` fixture provides a temporary directory."""
    assert tmp_path.is_dir()

def test_with_tmp_path_factory(tmp_path_factory: pytest.TempPathFactory):
    """The `tmp_path_factory` fixture provides a factory for directories."""
    assert tmp_path_factory.mktemp("temp_dir").is_dir()

```

## Using fixtures to teardown

Documentation: [pytest fixture][], [fixture finalization][]

If you want to do clean up on the fixture after it's used, you can use `yield`
instead of `return`. The fixture will then run the code defined after the
`yield` statement, after the fixture-using test returns.

[fixture finalization]:
  https://docs.pytest.org/en/latest/fixture.html#teardown-cleanup-aka-fixture-finalization
[pytest fixture]:
  https://docs.pytest.org/en/latest/reference.html#pytest-fixture

```python
%%run_pytest[clean] -qq -s --cache-clear


@pytest.fixture
def example_data_file_with_teardown() -> typing.Generator[pathlib.Path, None, None]:
    """Yield a large file, then delete it after each test completes."""
    large_data_file = fetch_file_from_s3()
    yield large_data_file
    print("Cleaning up file: {}".format(large_data_file))
    large_data_file.unlink()


def test_fixture_teardown_1(example_data_file_with_teardown: pathlib.Path):
    assert example_data_file_with_teardown.exists()


def test_fixture_teardown_2(example_data_file_with_teardown: pathlib.Path):
    assert example_data_file_with_teardown.exists()
```


## Scoping fixtures

Documentation: [scope sharing][]

[scope sharing]:
  https://docs.pytest.org/en/latest/fixture.html#scope-sharing-fixtures-across-classes-modules-packages-or-session

In the example above the code after the `yield` runs every time the fixture is
used, this might be inappropriate if the fixture computationally expensive. An
alternative to caching the result (described below), would be to set the scope
of the fixture with `pytest.fixture(scope=...)`. For example
`pytest.fixture(scope="session")` will run only once for the enture pytest
session. Possible values for `scope=...` are
`["class", "module", "package", "session"]`. A `Callable` can also be passed
which will be evaluated once, see [dynamic scope][].

[dynamic scope]: https://docs.pytest.org/en/latest/fixture.html#dynamic-scope

```python
%%run_pytest[clean] -qq -s --cache-clear


@pytest.fixture(scope="session")
def example_data_file_for_session() -> typing.Generator[pathlib.Path, None, None]:
    """Yield a large file, then delete it after the test completes."""
    large_data_file = fetch_file_from_s3()
    yield large_data_file
    print("Cleaning up file: {}".format(large_data_file))
    large_data_file.unlink()


def test_fixture__session_teardown_1(example_data_file_for_session: pathlib.Path):
    print("Running test 1")
    assert example_data_file_for_session.exists()


def test_fixture_session_teardown_2(example_data_file_for_session: pathlib.Path):
    print("Running test 2")
    assert example_data_file_for_session.exists()
```


## Parameterising fixtures

If you find yourself using the same `pytest.mark.parametrize` multiple times in
your tests, this can be refactored into a fixture using
`pytest.fixture(params=...)`

```python
%%run_pytest[clean] -qq -s --cache-clear


@pytest.fixture(params=["", tempfile.mkdtemp(), "/non_existing_file"])
def invalid_file(request) -> pathlib.Path:
    return pathlib.Path(request.param)


def test_file_1(invalid_file):
    with pytest.raises(FileNotFoundError):
        check_input_file(invalid_file)
    print("Unit test passes checking for input file: {}".format(invalid_file))


def test_cli_app(invalid_file):
    assert run_cli(invalid_file) == 1
    print("CLI test passes checking for file: {}".format(invalid_file))
```


## Break up expensive serial tests

There can be scenarios in end to end tests where it's necessary to test the
output artifact with multiple assertions. An example of this might be:

```python tags=["remove_output"]
%%run_pytest[clean] -qq -s --cache-clear


def test_long_e2e_test(tmp_path: pathlib.Path):
    """Long running e2e test."""

    # Assume this data was generated from an expensive computation that takes a few
    # minutes to run each time.
    raw_data_file, averages_data_file = long_running_computation()

    # If these tests fail ...
    assert raw_data_file.exists()
    assert raw_data_file.read_text()

    # ... these won't be executed.
    # Which can be brittle and need multiple iterations before all assertions are run.
    assert averages_data_file.exists()
    assert averages_data_file.read_text()
```


A problem with test structure above is that running a lot of tests in serial
means the later tests won't execute if any of the earlier ones fail which can
require running the same tests multiple times until all the serial tests
execute. These can instead be rewritten to take advantage of fixtures and still
run all the tests even if some fail

```python tags=["remove_output"]
%%run_pytest[clean] -qq -s --cache-clear


# Move the long running code into a fixture and make sure it runs only once per
# testing session
@pytest.fixture(scope="session")
def computation_data(
    tmp_path_factory: pytest.TempPathFactory,
) -> typing.Dict[str, pathlib.Path]:
    # This data was generated by a long compuation.
    raw_collected_data = long_running_computation()

    # tmp_path_factory is a fixture provided by pytest:
    # https://docs.pytest.org/en/stable/tmpdir.html#tmp-path-factory-example
    tmp_path = tmp_path_factory.mktemp("e2e_test")

    # Same generated output files
    raw_file = tmp_path / "raw_data.csv"
    raw_file.write_text(raw_collected_data.to_csv())
    averages_file = tmp_path / "sample_averages.csv"
    averages_file.write_text(
        raw_collected_data.groupby(["sample_id"]).agg("mean").to_csv()
    )

    # Return the files for testing.
    return {"raw": raw_file, "averages": averages_file}


# Both these tests use the compuation data as a fixture.
# Which means if either test fails, the other tests will still run.
# This can also make the tests more modular and easy to read.


def test_raw_data_file(computation_data: typing.Dict[str, pathlib.Path]):
    raw_data_file = computation_data["raw"]
    assert raw_data_file.exists()
    assert raw_data_file.read_text()


def test_averates_data_file(computation_data: typing.Dict[str, pathlib.Path]):
    averages_file = computation_data["averages"]
    assert averages_file.exists()
    assert averages_file.read_text()
```


## Use LineMatcher for testing large text

The `LineMatcher` helper class provides methods that can reduce boiler plate
testing large blocks of text.

```python tags=["remove_output"]
%%run_pytest[clean] -qq -s --quiet


def test_large_text():
    example_text = textwrap.dedent(
        """
        Two roads diverged in a yellow wood,
        And sorry I could not travel both
        And be one traveler, long I stood
        And looked down one as far as I could
        To where it bent in the undergrowth;
    """
    )

    matcher = _pytest.pytester.LineMatcher(example_text.splitlines())

    # Check some lines at random
    matcher.fnmatch_lines_random(["Two roads diverged in a yellow wood,"])

    # Check lines exist with a regex
    matcher.re_match_lines_random(["Two roads diverged in a .* wood,"])

    # Check lines don't exist with a regex
    matcher.no_fnmatch_line("And looked down two as far as I could")
```


## Caching large files or computation

Documentation: [Cache config][cache]

Pytest allows caching expensive operations between test runs such as large
computation or fetching data. This can used prevent expensive computations from
slowing down tests. The cache can be cleared using the flag:
`pytest --cache-clear`.

To access the cache the `pytestconfig` fixture needs to be in arguments to a
fixture, this will be an instance of [`_pytest.config.Config`][config_class].
The caveat to using the `get/set` methods is they have to be JSON serialisable,
so in the examples below I covert `pathlib.Path` objects back and forth to
strings to serialise into the cache.

[cache]:
  https://docs.pytest.org/en/stable/cache.html#the-new-config-cache-object
[config_class]: https://docs.pytest.org/en/latest/reference.html#id35

```python
%%run_pytest[clean] -qq -s --cache-clear


@pytest.fixture
def example_data_file(pytestconfig: _pytest.config.Config) -> pathlib.Path:
    """Fetch and cache a large file from s3.

    Notes:
        If the file is in the cache, return it. If it's not in the cache,
        then fetch it, cache it, then return it. This will be cached across
        multiple testing sessions.

    """
    if not (data_file := pytestconfig.cache.get("file_key", None)):
        data_file = fetch_file_from_s3()
        pytestconfig.cache.set("file_key", str(data_file))
    else:
        print("Using cached version of file.")

    return pathlib.Path(data_file)


def test_file_1(example_data_file: pathlib.Path):
    """This test will use the non-cached version."""
    print("Running test 1")
    assert example_data_file.exists()


def test_file_2(example_data_file: pathlib.Path):
    """Second time around this will use the cached version."""
    print("Running test 2")
    assert example_data_file.exists()
```
