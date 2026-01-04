"""
Tests for pycaschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pycaschooldata
    assert pycaschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pycaschooldata
    assert hasattr(pycaschooldata, 'fetch_enr')
    assert callable(pycaschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pycaschooldata
    assert hasattr(pycaschooldata, 'get_available_years')
    assert callable(pycaschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pycaschooldata
    assert hasattr(pycaschooldata, '__version__')
    assert isinstance(pycaschooldata.__version__, str)
