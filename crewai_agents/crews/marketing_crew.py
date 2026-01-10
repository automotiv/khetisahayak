from crewai import Crew, Task, Process
from ..agents.all_agents import (
    create_cmo,
    create_vp_marketing,
    create_creative_director,
    create_director_of_content,
    create_director_of_social,
    create_director_of_community,
    create_twitter_manager,
    create_linkedin_manager,
    create_discord_manager,
    create_twitch_manager,
    create_blog_editor,
    create_video_producer,
)


class MarketingCrew:
    
    def __init__(self):
        self.cmo = create_cmo()
        self.vp_marketing = create_vp_marketing()
        self.creative_director = create_creative_director()
        self.director_content = create_director_of_content()
        self.director_social = create_director_of_social()
        self.director_community = create_director_of_community()
        self.twitter_manager = create_twitter_manager()
        self.linkedin_manager = create_linkedin_manager()
        self.discord_manager = create_discord_manager()
        self.twitch_manager = create_twitch_manager()
        self.blog_editor = create_blog_editor()
        self.video_producer = create_video_producer()
    
    def create_campaign_crew(self, campaign_brief: str) -> Crew:
        tasks = [
            Task(
                description=f"Define marketing strategy for: {campaign_brief}",
                expected_output="Marketing strategy document",
                agent=self.cmo
            ),
            Task(
                description=f"Create creative direction for: {campaign_brief}",
                expected_output="Creative brief and visual direction",
                agent=self.creative_director
            ),
            Task(
                description=f"Develop content plan for: {campaign_brief}",
                expected_output="Content calendar and assets",
                agent=self.director_content
            ),
            Task(
                description=f"Plan social media strategy for: {campaign_brief}",
                expected_output="Social media plan with posts",
                agent=self.director_social
            ),
        ]
        
        return Crew(
            agents=[self.cmo, self.creative_director, self.director_content, self.director_social],
            tasks=tasks,
            process=Process.sequential,
            verbose=True
        )
    
    def create_social_media_crew(self) -> Crew:
        return Crew(
            agents=[
                self.director_social,
                self.twitter_manager,
                self.linkedin_manager,
                self.discord_manager,
            ],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
    
    def create_content_crew(self) -> Crew:
        return Crew(
            agents=[self.director_content, self.blog_editor, self.video_producer],
            tasks=[],
            process=Process.sequential,
            verbose=True
        )
