// app/routes/blog/index.tsx
import { useState } from 'react';
import type { Route } from './+types/index';
import type { Post, StrapiResponse, StrapiPost } from '~/types';
import PostCard from '~/components/PostCard';
import Pagination from '~/components/Pagination';
import PostFilter from '~/components/PostFilter';
import { getJSON, absMediaUrl } from '~/lib/api';

export async function loader(): Promise<{ posts: Post[] }> {
  try {
    // /posts → le helper ajoutera /api + base URL
    const json = await getJSON<StrapiResponse<StrapiPost>>(
      `/posts?populate=image&sort[0]=date:desc`
    );

    const posts: Post[] = json.data.map((item) => ({
      id: item.id,
      title: item.title,
      excerpt: item.excerpt,
      slug: item.slug,
      date: item.date,
      body: item.body,
      image: item.image?.url ? absMediaUrl(item.image.url) : '/images/no-image.png',
    }));

    return { posts };
  } catch (e: any) {
    console.error('Blog loader error:', e?.message || e);
    // On évite de throw pour ne pas casser la page
    return { posts: [] };
  }
}

const BlogPage = ({ loaderData }: Route.ComponentProps) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const postsPerPage = 10;

  const { posts } = loaderData as { posts: Post[] };

  const filteredPosts = posts.filter((post) => {
    const query = searchQuery.toLowerCase();
    return (
      (post.title || '').toLowerCase().includes(query) ||
      (post.excerpt || '').toLowerCase().includes(query)
    );
  });

  const totalPages = Math.ceil(filteredPosts.length / postsPerPage);
  const indexOfLast = currentPage * postsPerPage;
  const indexOfFirst = indexOfLast - postsPerPage;
  const currentPosts = filteredPosts.slice(indexOfFirst, indexOfLast);

  return (
    <div className='max-w-3xl mx-auto mt-10 px-6 py-6 bg-gray-900'>
      <h2 className='text-3xl text-white font-bold mb-8'>📝 Blog</h2>

      <PostFilter
        searchQuery={searchQuery}
        onSearchChange={(query) => {
          setSearchQuery(query);
          setCurrentPage(1);
        }}
      />

      <div className='space-y-8'>
        {currentPosts.length === 0 ? (
          <p className='text-gray-400 text-center'>No posts found</p>
        ) : (
          currentPosts.map((post) => <PostCard key={post.slug} post={post} />)
        )}
      </div>

      {totalPages > 1 && (
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={(page) => setCurrentPage(page)}
        />
      )}
    </div>
  );
};

export default BlogPage;
