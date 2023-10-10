@enum ForecastModes histval calibsmoother estimation

function forecasting!(; periods, forecast_mode::ForecastModes, context=context, datafile="", first_obs=1, last_obs=0, order=1)
    results = context.results.model_results[1]
    Y = forecasting_(; periods, forecast_mode, context=context, datafile=datafile, 
                       first_obs=first_obs, last_obs=last_obs, order=order)
    results.forecast = [AxisArrayTable(Y, 
                        Undated(0):Undated(periods), 
                        [Symbol(v) for v in get_endogenous(context.symboltable)])]
    return forecast
end

function forecasting_(; periods, forecast_mode::ForecastModes, context=context, datafile="", first_obs=1, last_obs=0, order=1)
    model = context.models[1]
    nendo = model.endogenous_nbr
    nexo = model.exogenous_nbr
    results = context.results.model_results[1]
    Y = Matrix{Float64}(undef, periods + 1, nendo)
    c = results.trends.endogenous_steady_state
    A = zeros(model.endogenous_nbr, model.endogenous_nbr)
    B = zeros(model.endogenous_nbr, model.exogenous_nbr)
    let y0
        if forecast_mode == histval
            y0 = copy(results.trends.endogenous_steady_state)
            for (i, v) in enumerate(context.work.histval[end,:])
                !ismissing(v) && (y0[i] = v)
            end
        elseif forecast_mode == calibsmoother
            calibsmoother!(context=context, datafile=datafile, first_obs=first_obs, last_obs=last_obs)
            @views y0 = Vector(results.smoother[end, :])
        end 
        
        make_A_B!(A, B, model, results)
        if order == 1
            forecast_!(Y, y0, c, A, B, periods)
        end
    end 
end

function recursive_forecast!(; first_period, 
                               last_period, 
                               forecast_mode::ForecastModes, 
                               context=context, datafile="", 
                               first_obs=1, 
                               last_obs=0, 
                               order=1)
    forecasts = context.results.model_results[1].forecasts
    for p = first_period:last_period
        forecast()
    end
end

function conditional_forecast!
end

function recursive_conditional_forecast!
end
    

function forecast_!(Y::AbstractMatrix, y0::AbstractVector, c::AbstractVector,
    A::AbstractMatrix, B::AbstractMatrix, periods::Integer)
    x = zeros(periods + 1, size(B, 2))
    simul_first_order!(Y, y0, x, c, A, B, periods)
    return Y
end