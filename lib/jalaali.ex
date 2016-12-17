defmodule Jalaali do
  @moduledoc """
  Jalaali module helps converting gregorian dates to jalaali dates.
  Jalaali calendar is widely used in Persia and Afganistan.

  This module helps you with converting erlang and/or elixir DateTime formats to Jalaali date and vice versa
  """

  @doc """
  Converts an erlang date to Jalaali date in erlang format

  ## Parameters
    - arg1: Date in erlang format (a tuple with three elements)

  ## Exmaples
    iex> Jalaali.to_jalaali {2016, 12, 17}
    {1395, 9, 27}
  """
  @spec to_jalaali(Tuple.t) :: Tuple.t
  def to_jalaali({gy, gm, gd}) do
    d2j(g2d({gy, gm, gd}))
  end

  @doc """
  Converts an erlang dateTime to Jalaali dateTime in erlang format

  ## Parameters
    - arg1: Date in erlang format (a tuple with three elements)

  ## Exmaples
    iex> Jalaali.to_jalaali {{2016, 12, 17}, {11, 11, 11}}
    {{1395, 9, 27}, {11, 11, 11}}
  """
  @spec to_jalaali(Tuple.t) :: Tuple.t
  def to_jalaali({date, time}) do
    {to_jalaali(date), time}
  end

  @doc """
  Converts an erlang dateTime to Jalaali dateTime in erlang format

  ## Parameters
    - arg1: Date in erlang format (a tuple with three elements)

  ## Exmaples
    iex> Jalaali.to_jalaali {{2016, 12, 17}, {11, 11, 11}}
    {{1395, 9, 27}, {11, 11, 11}}
  """
  @spec to_jalaali(DateTime.t | Date.t) :: DateTime.t | Date.t
  def to_jalaali(ex_dt) do

    {jy, jm, jd} = to_jalaali({ex_dt.year, ex_dt.month, ex_dt.day})
    %{ex_dt | year: jy, month: jm, day: jd}
  end

  def to_gregorian({jy, jm, jd}) do
    d2g(j2d({jy, jm, jd}))
  end

  def to_gregorian({date, time}) do
    {to_gregorian(date), time}
  end

  def to_gregorian(ex_dt) do
    {gy, gm, gd} = to_gregorian({ex_dt.year, ex_dt.month, ex_dt.day})
    %{ex_dt | year: gy, month: gm, day: gd}
  end

  def is_valid_jalali_date({jy, jm, jd}) do
    year_is_valid = (-61 <= jy <= 3177)
    month_is_valid = (1 <= jm <= 12)
    day_is_valid = (1 <= jd <= Jalaali.jalaali_month_length(jy, jm))

    year_is_valid && month_is_valid && day_is_valid
  end

  def is_leap_jalaali_year(jy) do
    jal_cal(jy).leap == 0
  end

  def jalaali_month_length(jy, jm) do
    cond do
      jm <= 6 -> 31
      jm <= 11 -> 30
      is_leap_jalaali_year(jy) -> 30
      true -> 29
    end
  end

  defp jal_cal(jy) do
    breaks = [-61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097, 2192, 2262, 2324,
                  2394, 2456,
                  3178]
    gy = jy + 621

    if jy < -61 or jy >= 3178 do
      raise "Invalid Jalaali year #{jy}"
    end

    {jump, jp, leap_j} = calc_jlimit(breaks, jy, {Enum.at(breaks, 0), -14}, 1)

    n = jy - jp

    leap_j1 =
      cond do
        mod(jump, 33) == 4 && jump - jy - jp == 4 ->
          leap_j + div(n, 33) * 8 + div(mod(n, 33) + 3, 4) + 1
        true ->
          leap_j + div(n, 33) * 8 + div(mod(n, 33) + 3, 4)
      end

    leap_g = div(gy, 4) - div((div(gy, 100) + 1) * 3, 4) - 150

    march = 20 + leap_j1 - leap_g

    n = cond do
      jump - jy - jp < 6 ->
        n - jump + div(jump + 4, 33) * 33
      true ->
        jy - jp
    end

    leap_c = mod(mod(n + 1, 33) - 1, 4)

    leap = case leap_c do
      -1 -> 4
      _ -> leap_c
    end

    %{leap: leap, gy: gy, march: march}
  end

  defp calc_jlimit(breaks, jy, {jp, leap_j}, index) do
    jm = Enum.at(breaks, index)
    jump = jm - jp
    cond do
      jy < jm ->
        {jump, jp, leap_j}
      true ->
        calc_jlimit(breaks, jy, {jm, leap_j + div(jump, 33) * 8 + div(mod(jump, 33), 4)}, index + 1)
    end
  end

  defp j2d({jy, jm, jd}) do
    r = jal_cal(jy)
    g2d({r.gy, 3, r.march}) + (jm - 1) * 31 - div(jm, 7) * (jm - 7) + jd - 1
  end

  defp d2j(jdn) do
    gy = elem(d2g(jdn), 0)  # calculate gregorian year (gy)
    jy = gy - 621
    r = jal_cal(jy)
    jdn1f = g2d({gy, 3, r.march})
    # find number of days that passed since 1 farvardin
    k = jdn - jdn1f
    cond do
      k <= 185 && k >= 0 -> {jy, div(k, 31) + 1, mod(k, 31) + 1}
      k >= 0 ->
        k = k - 186

        jm = 7 + div(k, 30)
        jd = mod(k, 30) + 1
        {jy, jm, jd} # HACK: remove duplication
      r.leap == 1 ->
        jy = jy - 1
        k = k + 180

        jm = 7 + div(k, 30)
        jd = mod(k, 30) + 1
        {jy, jm, jd} # HACK: remove duplication
      true ->
        jy = jy - 1
        k = k + 179

        jm = 7 + div(k, 30)
        jd = mod(k, 30) + 1
        {jy, jm, jd} # HACK: remove duplication
    end
  end

  defp g2d({gy, gm, gd}) do
    d = div((gy + div(gm - 8, 6) + 100100) * 1461, 4) + div(153 * mod(gm + 9, 12) + 2, 5) + gd - 34840408
    d - div(div(gy + 100100 + div(gm - 8, 6), 100) * 3, 4) + 752
  end

  defp d2g(jdn) do
    j = 4 * jdn + 139361631 + div(div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908
    i = div(mod(j, 1461), 4) * 5 + 308
    gd = div(mod(i, 153), 5) + 1
    gm = mod(div(i, 153), 12) + 1
    gy = div(j, 1461) - 100100 + div(8 - gm, 6)
    {gy, gm, gd}
  end

  defp mod(a, b) do
    a - div(a, b) * b
  end
end
