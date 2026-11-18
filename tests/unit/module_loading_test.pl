:- use_module(library(plunit)).

:- begin_tests(module_loading).

:- use_module('../../src/main.pl').

test(main_module_loaded) :-
    current_module(main).

test(io_modules_loaded) :-
    current_module(combinations_loader),
    current_module(policy_loader),
    current_module(result_writer).

test(domain_modules_loaded) :-
    current_module(evaluator),
    current_module(combination_queries).

test(rule_modules_loaded) :-
    current_module(career_balance),
    current_module(area_limit),
    current_module(incompatibility).

:- end_tests(module_loading).