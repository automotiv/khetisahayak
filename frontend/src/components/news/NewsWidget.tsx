import React from 'react';
import { Box, Typography, Card, CardContent, Stack, Link } from '@mui/material';
import { Article } from '@mui/icons-material';

interface NewsArticle {
  title: string;
  description?: string;
  url?: string;
  image?: string;
  publishedAt?: string;
  source?: string;
}

interface NewsWidgetProps {
  articles: NewsArticle[];
}

const NewsWidget: React.FC<NewsWidgetProps> = ({ articles = [] }) => {
  if (!articles || articles.length === 0) {
    return (
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Article color="primary" /> Agricultural News
          </Typography>
          <Typography variant="body2" color="text.secondary">
            No news articles available at the moment.
          </Typography>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Article color="primary" /> Agricultural News
        </Typography>
        <Stack spacing={1.5}>
          {articles.slice(0, 5).map((article, index) => (
            <Box key={index} sx={{ borderBottom: index < articles.length - 1 ? 1 : 0, borderColor: 'divider', pb: 1 }}>
              <Typography variant="body2" fontWeight="medium">
                {article.url ? (
                  <Link href={article.url} target="_blank" rel="noopener" underline="hover">
                    {article.title}
                  </Link>
                ) : (
                  article.title
                )}
              </Typography>
              {article.description && (
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
                  {article.description.slice(0, 100)}...
                </Typography>
              )}
              {article.source && (
                <Typography variant="caption" color="text.secondary">
                  {article.source}
                </Typography>
              )}
            </Box>
          ))}
        </Stack>
      </CardContent>
    </Card>
  );
};

export default NewsWidget;
