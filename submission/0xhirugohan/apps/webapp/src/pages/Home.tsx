import ReactLogo from '../assets/react.svg'

const HomePage = () => {
    return <div className="w-full min-h-screen flex flex-col gap-y-8 justify-center items-center">
        <img
            className="animate-spin w-16"
            src={ReactLogo}
            alt="react logo"
        />
        <h1
            className="text-3xl font-semibold"
        >
            Create-Web3
        </h1>
        <p className="text-center">
            Get started by editing <span className="underline underline-offset-2">apps/webapp/src/pages/Home.tsx</span>
        </p>
    </div>
}

export default HomePage;