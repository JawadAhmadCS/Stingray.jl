@testset "LightCurve Tests" begin
    test_dir = mktempdir()
    sample_file = joinpath(test_dir, "sample_lightcurve.fits")
    
    # Sample Data
    times = [0.1, 0.5, 1.2, 2.4, 3.0, 4.1, 5.6, 6.8, 7.9, 9.2]
    energies = [100, 200, 150, 180, 250, 300, 275, 220, 190, 210]
    metadata = Dict("TELESCOP" => "TestScope", "MISSION" => "TestMission")
    
    # Create a sample FITS file for testing
    f = FITS(sample_file, "w")
    write(f, Int[])  # Empty primary array
    table = Dict("TIME" => times, "ENERGY" => energies)
    write(f, table)
    close(f)

    @test isfile(sample_file)

    # Test reading the sample file
    eventlist = readevents(sample_file)
    @test eventlist.filename == sample_file
    @test length(eventlist.times) == length(times)
    @test length(eventlist.energies) == length(energies)

    # Test different bin sizes
    for bin_size in [1.0, 0.5, 2.0, 1.3]
        lightcurve = create_lightcurve(eventlist, bin_size, err_method=:poisson)
    
        # Validate LightCurve properties
        @test all(lightcurve.counts .>= 0)
        @test lightcurve.err_method == :poisson
        @test length(lightcurve.timebins) == length(lightcurve.counts)
    
        # Compute expected counts using Histogram directly
        bins = minimum(eventlist.times):bin_size:maximum(eventlist.times)
        expected_hist = fit(Histogram, eventlist.times, bins)
        expected_counts = expected_hist.weights
    
        # Explicitly verify count correctness
        @test lightcurve.counts == expected_counts
    end
end