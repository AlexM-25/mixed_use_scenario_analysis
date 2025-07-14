# mixed_use_scenario_analysis
This MATLAB project models the financial performance of mixed-use real estate developments, combining residential and commercial components. It calculates cash flows, internal rate of return (IRR), and break-even year under multiple user-defined scenarios, allowing robust sensitivity and feasibility analysis.

IRR is calculated using the Newton-Raphson nonlinear root-finding method on the Net Present Value (NPV) equation:

NPV(r)=∑_(t=0)^n▒〖C_t/〖(1+r)〗^t =0〗

This method is fast and accurate for IRR problems involving multiple uneven cash flows.

