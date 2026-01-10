from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_director_of_qa,
    create_manager_qa,
    create_manager_test_automation,
    create_qa_engineer,
    create_qa_engineer_1,
    create_qa_engineer_2,
    create_qa_engineer_3,
)


class QACrew:
    
    def __init__(self):
        self.director_qa = create_director_of_qa()
        self.manager_qa = create_manager_qa()
        self.manager_automation = create_manager_test_automation()
        self.qa_engineer = create_qa_engineer()
        self.qa_engineer_1 = create_qa_engineer_1()
        self.qa_engineer_2 = create_qa_engineer_2()
        self.qa_engineer_3 = create_qa_engineer_3()
    
    def create_testing_crew(self, feature_to_test: str) -> Crew:
        tasks = [
            Task(
                description=f"Create test strategy for: {feature_to_test}",
                expected_output="Test strategy document with test plan",
                agent=self.manager_qa
            ),
            Task(
                description=f"Design automated tests for: {feature_to_test}",
                expected_output="Automated test suite design",
                agent=self.manager_automation
            ),
            Task(
                description=f"Execute manual testing for: {feature_to_test}",
                expected_output="Manual test results and bug reports",
                agent=self.qa_engineer
            ),
            Task(
                description=f"Implement automated tests for: {feature_to_test}",
                expected_output="Automated test implementation",
                agent=self.qa_engineer_1
            ),
        ]
        
        return Crew(
            agents=[self.manager_qa, self.manager_automation, self.qa_engineer, self.qa_engineer_1],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
