%% 
clc; clear;

% --- Define Scenarios with stronger tweaks for target IRR 15-25% ---
scenarios = {
    struct('name', 'Target IRR 15-25%', ...
           'units', struct('residential', 120, 'commercial', 60), ...
           'costs', struct('residential', 180000, 'commercial', 280000), ...
           'sales_price', struct('residential', 370000, 'commercial', 520000), ... % +~15%
           'opex', 4200, ...                % -30% from 6000
           'presale_rate', 0.25, ...
           'absorption', struct('residential', 0.26, 'commercial', 0.30), ... % +~20%
           'years', 6),
    struct('name', 'Base Case', ...
           'units', struct('residential', 100, 'commercial', 50), ...
           'costs', struct('residential', 300000, 'commercial', 450000), ...
           'sales_price', struct('residential', 350000, 'commercial', 500000), ...
           'opex', 10000, ...
           'presale_rate', 0.2, ...
           'absorption', struct('residential', 0.2, 'commercial', 0.25), ...
           'years', 5),
    struct('name', 'High Presale', ...
           'units', struct('residential', 100, 'commercial', 50), ...
           'costs', struct('residential', 200000, 'commercial', 300000), ...
           'sales_price', struct('residential', 350000, 'commercial', 500000), ...
           'opex', 10000, ...
           'presale_rate', 0.5, ...
           'absorption', struct('residential', 0.2, 'commercial', 0.25), ...
           'years', 5),
    struct('name', 'Slow Absorption', ...
           'units', struct('residential', 100, 'commercial', 50), ...
           'costs', struct('residential', 200000, 'commercial', 300000), ...
           'sales_price', struct('residential', 350000, 'commercial', 500000), ...
           'opex', 10000, ...
           'presale_rate', 0.2, ...
           'absorption', struct('residential', 0.1, 'commercial', 0.1), ...
           'years', 7)
};

model_summaries = struct('Scenario', {}, 'IRR', {}, 'BreakEvenYear', {}, 'TotalCashflow', {});

for i = 1:length(scenarios)
    s = scenarios{i};
    [cf, irr, be_year] = run_mixed_use_model(s.units, s.costs, s.sales_price, ...
                                             s.opex, s.presale_rate, ...
                                             s.absorption, s.years);
    model_summaries(end+1) = struct( ...
        'Scenario', s.name, ...
        'IRR', irr, ...
        'BreakEvenYear', be_year, ...
        'TotalCashflow', sum(cf) ...
    );
end

model_summary_table = struct2table(model_summaries);
disp(model_summary_table);

writetable(model_summary_table, 'MixedUse_Model_Summary.xlsx');



function [cashflows, irr, break_even_year] = run_mixed_use_model(units, costs, sales_price, opex, presale_rate, absorption, years)
    product_types = fieldnames(units);
    cashflows = zeros(1, years + 1);

    % Calculate total cost and presale cash at Year 0
    total_cost = 0;
    total_presale_cash = 0;
    for i = 1:length(product_types)
        type = product_types{i};
        total_cost = total_cost + units.(type) * costs.(type);
        presold_units = round(presale_rate * units.(type));
        total_presale_cash = total_presale_cash + presold_units * sales_price.(type);
    end

    % Initial investment: total cost less presale cash inflow
    cashflows(1) = -total_cost + total_presale_cash;

    % Model cashflows over absorption period
    for i = 1:length(product_types)
        type = product_types{i};
        total_units = units.(type);
        cost = costs.(type);
        price = sales_price.(type);
        ab_rate = absorption.(type);

        presold_units = round(presale_rate * total_units);
        remaining_units = total_units - presold_units;

        for y = 1:years
            delivered_units = round(ab_rate * total_units);
            if delivered_units > remaining_units
                delivered_units = remaining_units;
            end

            cash_in = delivered_units * price;
            cash_out = delivered_units * cost + opex;  % fixed annual opex cost

            cashflows(y+1) = cashflows(y+1) + cash_in - cash_out;

            remaining_units = remaining_units - delivered_units;
            if remaining_units <= 0
                break;
            end
        end
    end

    % IRR Calculation (Newton-Raphson)
    f = @(r) sum(cashflows ./ (1 + r).^(0:length(cashflows)-1));
    df = @(r) sum(-cashflows .* (0:length(cashflows)-1) ./ (1 + r).^(1:length(cashflows)));
    r = 0.1;
    for iter = 1:100
        r_new = r - f(r)/df(r);
        if abs(r_new - r) < 1e-6
            break;
        end
        r = r_new;
    end
    irr = r;

    % Break-even year calculation
    cum_cf = cumsum(cashflows);
    idx = find(cum_cf >= 0, 1);
    break_even_year = idx - 1; % zero-based year index
    if isempty(break_even_year)
        break_even_year = NaN;
    end
end

