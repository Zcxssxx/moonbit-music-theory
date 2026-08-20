///|
test "quantization handles exact ties consistently" {
  let grid = BeatGrid::new(ppq=480, subdivision=4)
  inspect(grid.quantize_tick(240, QuantizeMode::HalfUp), content="240")
  inspect(grid.quantize_tick(360, QuantizeMode::HalfUp), content="480")
}

///|
test "beat grid validates positive ppq and subdivision" {
  try BeatGrid::new(ppq=0, subdivision=4) catch {
    err =>
      inspect(err.to_string().contains("ppq must be positive"), content="true")
  } noraise {
    _ => fail("expected invalid ppq error")
  }

  try BeatGrid::new(ppq=480, subdivision=0) catch {
    err =>
      inspect(
        err.to_string().contains("subdivision must be positive"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid subdivision error")
  }
}

///|
test "beat grid rejects unsupported time signatures and non-divisible grids" {
  try
    BeatGrid::new(
      ppq=480,
      subdivision=4,
      time_signature=TimeSignature::new(0, 4),
    )
  catch {
    err =>
      inspect(
        err.to_string().contains("time signature beats must be positive"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid beat count error")
  }

  try
    BeatGrid::new(
      ppq=480,
      subdivision=4,
      time_signature=TimeSignature::new(4, 3),
    )
  catch {
    err =>
      inspect(
        err
        .to_string()
        .contains("time signature beat value must be a positive power of two"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid beat value error")
  }

  try
    BeatGrid::new(
      ppq=480,
      subdivision=4,
      time_signature=TimeSignature::new(5, 8),
    )
  catch {
    err =>
      inspect(
        err.to_string().contains("unsupported time signature beat geometry"),
        content="true",
      )
  } noraise {
    _ => fail("expected unsupported geometry error")
  }

  try BeatGrid::new(ppq=100, subdivision=3) catch {
    err =>
      inspect(
        err
        .to_string()
        .contains("subdivision does not divide evenly into ticks"),
        content="true",
      )
  } noraise {
    _ => fail("expected non-divisible grid error")
  }
}

///|
test "quantization applies floor and ceiling policies" {
  let grid = BeatGrid::new(ppq=480, subdivision=4)
  inspect(grid.quantize_tick(359, QuantizeMode::Floor), content="240")
  inspect(grid.quantize_tick(359, QuantizeMode::Ceiling), content="480")
}
