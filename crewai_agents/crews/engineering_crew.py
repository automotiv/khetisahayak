"""Engineering Crew - Backend, Frontend, Mobile, and DevOps teams."""

from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_cto,
    create_backend_tech_lead,
    create_frontend_tech_lead,
    create_mobile_tech_lead,
    create_devops_lead,
    create_solutions_architect,
    create_senior_backend_python_developer,
    create_senior_frontend_developer,
    create_senior_flutter_developer,
    create_senior_devops_engineer,
    create_database_specialist,
    create_security_engineer,
)


class EngineeringCrew:
    
    def __init__(self):
        self.cto = create_cto()
        self.backend_lead = create_backend_tech_lead()
        self.frontend_lead = create_frontend_tech_lead()
        self.mobile_lead = create_mobile_tech_lead()
        self.devops_lead = create_devops_lead()
        self.architect = create_solutions_architect()
        self.backend_dev = create_senior_backend_python_developer()
        self.frontend_dev = create_senior_frontend_developer()
        self.mobile_dev = create_senior_flutter_developer()
        self.devops_eng = create_senior_devops_engineer()
        self.db_specialist = create_database_specialist()
        self.security_eng = create_security_engineer()
    
    def create_feature_development_crew(self, feature_description: str) -> Crew:
        tasks = [
            Task(
                description=f"Review and approve the technical approach for: {feature_description}",
                expected_output="Technical approval with architecture guidelines",
                agent=self.cto
            ),
            Task(
                description=f"Design the system architecture for: {feature_description}",
                expected_output="Architecture design document with component diagrams",
                agent=self.architect
            ),
            Task(
                description=f"Design the database schema for: {feature_description}",
                expected_output="Database schema with migrations",
                agent=self.db_specialist
            ),
            Task(
                description=f"Implement backend APIs for: {feature_description}",
                expected_output="Backend API implementation with tests",
                agent=self.backend_dev
            ),
            Task(
                description=f"Implement frontend UI for: {feature_description}",
                expected_output="Frontend implementation with components",
                agent=self.frontend_dev
            ),
            Task(
                description=f"Implement mobile app screens for: {feature_description}",
                expected_output="Mobile app implementation",
                agent=self.mobile_dev
            ),
            Task(
                description=f"Set up deployment pipeline for: {feature_description}",
                expected_output="CI/CD configuration and deployment scripts",
                agent=self.devops_eng
            ),
            Task(
                description=f"Security review for: {feature_description}",
                expected_output="Security assessment report",
                agent=self.security_eng
            ),
        ]
        
        return Crew(
            agents=[
                self.cto, self.architect, self.db_specialist,
                self.backend_dev, self.frontend_dev, self.mobile_dev,
                self.devops_eng, self.security_eng
            ],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
    
    def create_backend_crew(self) -> Crew:
        return Crew(
            agents=[
                self.backend_lead,
                self.backend_dev,
                self.db_specialist,
            ],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
    
    def create_frontend_crew(self) -> Crew:
        return Crew(
            agents=[
                self.frontend_lead,
                self.frontend_dev,
            ],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
    
    def create_mobile_crew(self) -> Crew:
        return Crew(
            agents=[
                self.mobile_lead,
                self.mobile_dev,
            ],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
    
    def create_devops_crew(self) -> Crew:
        return Crew(
            agents=[
                self.devops_lead,
                self.devops_eng,
            ],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
