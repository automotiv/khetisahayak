from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_ceo,
    create_cto,
    create_cpo,
    create_cfo,
    create_cmo,
    create_coo,
    create_ciso,
    create_vp_engineering,
    create_vp_product,
    create_vp_marketing,
    create_vp_people,
    create_vp_design,
    create_vp_customer_success,
)


class ExecutiveCrew:
    
    def __init__(self):
        self.ceo = create_ceo()
        self.cto = create_cto()
        self.cpo = create_cpo()
        self.cfo = create_cfo()
        self.cmo = create_cmo()
        self.coo = create_coo()
        self.ciso = create_ciso()
        self.vp_engineering = create_vp_engineering()
        self.vp_product = create_vp_product()
        self.vp_marketing = create_vp_marketing()
        self.vp_people = create_vp_people()
        self.vp_design = create_vp_design()
        self.vp_customer_success = create_vp_customer_success()
    
    def create_strategic_planning_crew(self, initiative: str) -> Crew:
        tasks = [
            Task(
                description=f"Define strategic vision for: {initiative}",
                expected_output="Strategic vision document",
                agent=self.ceo
            ),
            Task(
                description=f"Assess technical feasibility for: {initiative}",
                expected_output="Technical feasibility assessment",
                agent=self.cto
            ),
            Task(
                description=f"Define product roadmap for: {initiative}",
                expected_output="Product roadmap with milestones",
                agent=self.cpo
            ),
            Task(
                description=f"Create financial projections for: {initiative}",
                expected_output="Financial projections and budget",
                agent=self.cfo
            ),
            Task(
                description=f"Develop marketing strategy for: {initiative}",
                expected_output="Marketing strategy document",
                agent=self.cmo
            ),
            Task(
                description=f"Plan operational execution for: {initiative}",
                expected_output="Operational execution plan",
                agent=self.coo
            ),
        ]
        
        return Crew(
            agents=[self.ceo, self.cto, self.cpo, self.cfo, self.cmo, self.coo],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
    
    def create_c_suite_crew(self) -> Crew:
        return Crew(
            agents=[self.ceo, self.cto, self.cpo, self.cfo, self.cmo, self.coo, self.ciso],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
