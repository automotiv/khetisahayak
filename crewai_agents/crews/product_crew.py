from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_cpo,
    create_product_manager,
    create_senior_pm_growth,
    create_pm_data_ml,
    create_pm_internal_tools,
    create_ui_ux_designer,
    create_head_of_research,
    create_ux_researcher,
)


class ProductCrew:
    
    def __init__(self):
        self.cpo = create_cpo()
        self.product_manager = create_product_manager()
        self.pm_growth = create_senior_pm_growth()
        self.pm_data_ml = create_pm_data_ml()
        self.pm_internal_tools = create_pm_internal_tools()
        self.ui_ux_designer = create_ui_ux_designer()
        self.head_of_research = create_head_of_research()
        self.ux_researcher = create_ux_researcher()
    
    def create_feature_planning_crew(self, feature_request: str) -> Crew:
        tasks = [
            Task(
                description=f"Define product strategy for: {feature_request}",
                expected_output="Product strategy document with success metrics",
                agent=self.cpo
            ),
            Task(
                description=f"Conduct user research for: {feature_request}",
                expected_output="User research findings and insights",
                agent=self.ux_researcher
            ),
            Task(
                description=f"Create product requirements for: {feature_request}",
                expected_output="PRD with user stories and acceptance criteria",
                agent=self.product_manager
            ),
            Task(
                description=f"Design UI/UX for: {feature_request}",
                expected_output="UI/UX designs and prototypes",
                agent=self.ui_ux_designer
            ),
        ]
        
        return Crew(
            agents=[self.cpo, self.ux_researcher, self.product_manager, self.ui_ux_designer],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
    
    def create_growth_crew(self) -> Crew:
        return Crew(
            agents=[self.pm_growth, self.head_of_research, self.ux_researcher],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
