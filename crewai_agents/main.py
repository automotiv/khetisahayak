#!/usr/bin/env python3
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from crewai_agents.agents.all_agents import get_all_agents, get_agent_by_name
from crewai_agents.crews import (
    EngineeringCrew,
    ProductCrew,
    MLCrew,
    QACrew,
    ExecutiveCrew,
    MarketingCrew,
)


def list_all_agents():
    print("\n=== Kheti Sahayak CrewAI Agents ===\n")
    agents = get_all_agents()
    for i, agent in enumerate(agents, 1):
        print(f"{i:3}. {agent.role}")
    print(f"\nTotal: {len(agents)} agents")


def run_engineering_feature(feature: str):
    print(f"\n=== Running Engineering Crew for: {feature} ===\n")
    crew = EngineeringCrew()
    feature_crew = crew.create_feature_development_crew(feature)
    result = feature_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def run_product_planning(feature: str):
    print(f"\n=== Running Product Crew for: {feature} ===\n")
    crew = ProductCrew()
    planning_crew = crew.create_feature_planning_crew(feature)
    result = planning_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def run_ml_development(task: str):
    print(f"\n=== Running ML Crew for: {task} ===\n")
    crew = MLCrew()
    ml_crew = crew.create_model_development_crew(task)
    result = ml_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def run_qa_testing(feature: str):
    print(f"\n=== Running QA Crew for: {feature} ===\n")
    crew = QACrew()
    testing_crew = crew.create_testing_crew(feature)
    result = testing_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def run_strategic_planning(initiative: str):
    print(f"\n=== Running Executive Crew for: {initiative} ===\n")
    crew = ExecutiveCrew()
    strategy_crew = crew.create_strategic_planning_crew(initiative)
    result = strategy_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def run_marketing_campaign(campaign: str):
    print(f"\n=== Running Marketing Crew for: {campaign} ===\n")
    crew = MarketingCrew()
    campaign_crew = crew.create_campaign_crew(campaign)
    result = campaign_crew.kickoff()
    print("\n=== Result ===")
    print(result)
    return result


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Kheti Sahayak CrewAI Agent System")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    subparsers.add_parser("list", help="List all available agents")
    
    eng_parser = subparsers.add_parser("engineering", help="Run engineering crew")
    eng_parser.add_argument("feature", help="Feature to develop")
    
    prod_parser = subparsers.add_parser("product", help="Run product planning crew")
    prod_parser.add_argument("feature", help="Feature to plan")
    
    ml_parser = subparsers.add_parser("ml", help="Run ML development crew")
    ml_parser.add_argument("task", help="ML task to execute")
    
    qa_parser = subparsers.add_parser("qa", help="Run QA testing crew")
    qa_parser.add_argument("feature", help="Feature to test")
    
    exec_parser = subparsers.add_parser("executive", help="Run executive planning crew")
    exec_parser.add_argument("initiative", help="Strategic initiative")
    
    mkt_parser = subparsers.add_parser("marketing", help="Run marketing campaign crew")
    mkt_parser.add_argument("campaign", help="Campaign brief")
    
    args = parser.parse_args()
    
    if args.command == "list":
        list_all_agents()
    elif args.command == "engineering":
        run_engineering_feature(args.feature)
    elif args.command == "product":
        run_product_planning(args.feature)
    elif args.command == "ml":
        run_ml_development(args.task)
    elif args.command == "qa":
        run_qa_testing(args.feature)
    elif args.command == "executive":
        run_strategic_planning(args.initiative)
    elif args.command == "marketing":
        run_marketing_campaign(args.campaign)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
