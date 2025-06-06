import { Outlet } from 'react-router'

import { Navbar } from './components'

const Layout = () => {
    return <>
        <Navbar />
        <Outlet />
    </>
}

export default Layout;