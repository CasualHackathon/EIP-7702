import { Link } from 'react-router'

const NotFoundPage = () => {
    return <div className="w-full min-h-screen flex flex-col justify-center items-center">
        <h1
            className="text-3xl font-semibold"
        >
            Page Not Found
        </h1>
        <Link
            to="/"
            className="mt-8 border-2 border-zinc-600 px-4 py-2 rounded-md font-semibold cursor-pointer hover:border-zinc-800 hover:shadow-lg shadow-md"
        >
            Back to Home
        </Link>
    </div>
}

export default NotFoundPage;