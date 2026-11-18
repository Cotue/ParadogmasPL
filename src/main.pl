:- module(main, []).

:- use_module('io/combinations_loader.pl').
:- use_module('io/policy_loader.pl').
:- use_module('io/result_writer.pl').

:- use_module('domain/evaluator.pl').
:- use_module('domain/combination_queries.pl').

:- use_module('rules/career_balance.pl').
:- use_module('rules/area_limit.pl').
:- use_module('rules/incompatibility.pl').